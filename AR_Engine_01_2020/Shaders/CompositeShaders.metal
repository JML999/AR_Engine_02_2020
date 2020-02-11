#include <metal_stdlib>
using namespace metal;

typedef struct {
    float2 position;
    float2 texCoord;
} CompositeVertex;

typedef struct {
    float4 position [[position]];
    float2 texCoordCamera;
    float2 texCoordScene;
} CompositeColorInOut;

struct SceneConstants{
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
};

// Convert from YCbCr to rgb
float4 ycbcrToRGBTransform(float4 y, float4 CbCr) {
    const float4x4 ycbcrToRGBTransform = float4x4(
      float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
      float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
      float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
      float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );

    float4 ycbcr = float4(y.r, CbCr.rg, 1.0);
    return ycbcrToRGBTransform * ycbcr;
}

// Composite the image vertex function.
vertex CompositeColorInOut compositeImageVertexTransform(const device CompositeVertex* cameraVertices [[ buffer(0) ]],
                                                         const device CompositeVertex* sceneVertices [[ buffer(1) ]],
                                                         unsigned int vid [[ vertex_id ]],
                                                         constant float3x3 &transform [[buffer(2)]]) {
    CompositeColorInOut out;

    const device CompositeVertex& cv = cameraVertices[vid];
    const device CompositeVertex& sv = sceneVertices[vid];

    out.position = float4(cv.position, 0.0, 1.0);
   
    out.texCoordCamera = (transform * float3(cv.texCoord, 1)).xy;
    out.texCoordScene = sv.texCoord;

    return out;
}

// Composite the image fragment function.
fragment half4 compositeImageFragmentShader(CompositeColorInOut in [[ stage_in ]],
                                    texture2d<float, access::sample> capturedImageTextureY [[ texture(0) ]],
                                    texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(1) ]],
                                    texture2d<float, access::sample> sceneColorTexture [[ texture(2) ]],
                                    depth2d<float, access::sample> sceneDepthTexture [[ texture(3) ]],
                                    texture2d<float, access::sample> alphaTexture [[ texture(4) ]],
                                    texture2d<float, access::sample> dilatedDepthTexture [[ texture(5) ]],
                                    constant SceneConstants &uniforms [[ buffer(1) ]])
{
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    float2 cameraTexCoord = in.texCoordCamera;
    float2 sceneTexCoord = in.texCoordScene;

    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate.
    float4 rgb = ycbcrToRGBTransform(capturedImageTextureY.sample(s, cameraTexCoord), capturedImageTextureCbCr.sample(s, cameraTexCoord));

    // Perform composition with the matting.
    half4 sceneColor = half4(sceneColorTexture.sample(s, sceneTexCoord));
    float sceneDepth = sceneDepthTexture.sample(s, sceneTexCoord);

    half4 cameraColor = half4(rgb);
    half alpha = half(alphaTexture.sample(s, cameraTexCoord).r);

    half showOccluder = 1.0;

    float dilatedLinearDepth = half(dilatedDepthTexture.sample(s, cameraTexCoord).r);

    // Project linear depth with the projection matrix.
    float dilatedDepth = clamp((uniforms.projectionMatrix[2][2] * -dilatedLinearDepth + uniforms.projectionMatrix[3][2]) / (uniforms.projectionMatrix[2][3] * -dilatedLinearDepth + uniforms.projectionMatrix[3][3]), 0.0, 1.0);

    showOccluder = (half)step(dilatedDepth, sceneDepth); // forwardZ case



    half4 occluderResult = mix(sceneColor, cameraColor, alpha);
    half4 mattingResult = mix(sceneColor, occluderResult, showOccluder);
    return mattingResult;
}

