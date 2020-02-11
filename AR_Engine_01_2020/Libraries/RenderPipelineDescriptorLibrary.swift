import MetalKit

enum RenderPipelineDescriptorTypes {
    case Basic
    case Video
    case Composite
}

class RenderPipelineDescriptorLibrary {
    
    private static var renderPipelineDescriptors: [RenderPipelineDescriptorTypes : RenderPipelineDescriptor] = [:]
    
    public static func Initialize() {
        createDefaultRenderPipelineDescriptors()
    }
    
    private static func createDefaultRenderPipelineDescriptors() {
        renderPipelineDescriptors.updateValue(Basic_RenderPipelineDescriptor(), forKey: .Basic)
        renderPipelineDescriptors.updateValue(VideoQuad_RenderPipelineDescriptor(), forKey: .Video)
        renderPipelineDescriptors.updateValue(Composite_RenderPipelineDescriptor(), forKey: .Composite)
    }
    
    public static func Descriptor(_ renderPipelineDescriptorType: RenderPipelineDescriptorTypes)->MTLRenderPipelineDescriptor{
        return renderPipelineDescriptors[renderPipelineDescriptorType]!.renderPipelineDescriptor
    }
    
}

protocol RenderPipelineDescriptor {
    var name: String { get }
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor! { get }
}

public struct Basic_RenderPipelineDescriptor: RenderPipelineDescriptor{
    var name: String = "Basic Render Pipeline Descriptor"
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor!
    init(){
        renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = Preferences.MainDepthPixelFormat
        renderPipelineDescriptor.vertexFunction = ShaderLibrary.Vertex(.Basic)
        renderPipelineDescriptor.fragmentFunction = ShaderLibrary.Fragment(.Basic)
        renderPipelineDescriptor.vertexDescriptor = VertexDescriptorLibrary.Descriptor(.Basic)
    }
}

public struct VideoQuad_RenderPipelineDescriptor: RenderPipelineDescriptor{
    var name: String = "Video Quad Render Pipeline Descriptor"
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor!
    init(){
        renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = ShaderLibrary.Vertex(.Video)
        renderPipelineDescriptor.fragmentFunction = ShaderLibrary.Fragment(.Video)
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        renderPipelineDescriptor.vertexDescriptor = VertexDescriptorLibrary.Descriptor(.Video)
    }
}

public struct Composite_RenderPipelineDescriptor: RenderPipelineDescriptor{
    var name: String = "Anchor Render Pipeline Descriptor"
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor!
    init(){
        renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.label = "MyCompositePipeline"
        
        renderPipelineDescriptor.sampleCount = 1
        
        renderPipelineDescriptor.vertexFunction = ShaderLibrary.Vertex(.Composite)
        renderPipelineDescriptor.fragmentFunction = ShaderLibrary.Fragment(.Composite)
        
        renderPipelineDescriptor.vertexDescriptor = VertexDescriptorLibrary.Descriptor(.Geometry)
        
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = Preferences.MainDepthPixelFormat
    }
}

