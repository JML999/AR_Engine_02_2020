import Foundation
import MetalKit
import ARKit
import simd
import CoreImage

public class SceneRenderer {
    public var device: MTLDevice
    private var bufferAllocator: BufferAllocator
    private var textureCache: CVMetalTextureCache
    
    public var scene: Scene?
    public var pointOfView: Node?
    public var interfaceOrientation: UIInterfaceOrientation = .portrait
    public var currentFrame: ARFrame?
    public var drawableSize = CGSize(width: 1, height: 1)
    
    private var textureLoader: MTKTextureLoader
    
    private var commandBuffer: MTLCommandBuffer!
    private var renderCommandEncoder: MTLRenderCommandEncoder!
    private var instanceUniformBuffer: MTLBuffer!
    private var instanceUniformBufferOffset: Int!
        
    private var imageProperty: MaterialProperty?
    private var modelConstants = ModelConstants()
    
    var recorder: Recorder?
    
     //MATTECODE-------------------------------------
    public var session: ARSession?      //Passed from ARMTKView build scene
    let matteGenerator: ARMatteGenerator
    
    var scenePlaneVertexBuffer: MTLBuffer!
    var imagePlaneVertexBuffer: MTLBuffer!
    
    var sharedUniformBuffer: MTLBuffer!
    var alphaTexture: MTLTexture?
    var dilatedDepthTexture: MTLTexture?
    
    // temporary render targets for 3d scene
    var sceneColorTexture: MTLTexture!
    var sceneDepthTexture: MTLTexture!
    
    var luma: CVMetalTexture?
    var chroma: CVMetalTexture?
    
    var frameUniforms: FrameUniforms?
    
    let vertices: [Float] = [
                            // x   y  s  t
                               -1.0, -1.0, 0.0, 1.0,
                                 1.0, -1.0, 1.0, 1.0,
                                 -1.0, 1.0, 0.0, 0.0,
                                 1.0, 1.0, 1.0, 0.0
                            ]
    
    // Used to determine _uniformBufferStride each frame.
    //   This is the current frame number modulo kMaxBuffersInFlight
    var uniformBufferIndex: Int = 0
    // Offset within _sharedUniformBuffer to set for the current frame
    var sharedUniformBufferOffset: Int = 0
    // Addresses to write shared uniforms to each frame
    var sharedUniformBufferAddress: UnsafeMutableRawPointer!
    //MATTECODE-------------------------------------
    
    public init(device: MTLDevice){
        self.device = device
        bufferAllocator = BufferAllocator(device: device)
        
        var textureCache: CVMetalTextureCache? = nil
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        self.textureCache = textureCache!
        
        textureLoader = MTKTextureLoader(device: device)
        matteGenerator = ARMatteGenerator(device: device, matteResolution: .full)
    }
    
    public func draw(in view: MTKView, completion: (()-> Void)){
        beginFrame()
        configureMatteRenderTargets(view: view)
        updateMatteTextures()
        
        guard let scene = scene, let pointOfView = pointOfView, let camera = pointOfView.camera else {return}
        
        if let frameCamera = currentFrame?.camera {
            let cameraTransform = frameCamera.viewMatrix(for: interfaceOrientation)
            pointOfView.transform = Transform(from: cameraTransform)
            pointOfView.camera?.projectionTransform = frameCamera.projectionMatrix(for: interfaceOrientation, viewportSize: view.bounds.size, zNear: 0.01, zFar: 100)
        }
        
        guard let pass = view.currentRenderPassDescriptor else {return}
        
        // Setup offscreen renderpass for later compositing
        let sceneRenderDescriptor: MTLRenderPassDescriptor = setUpOffscreenRenderPass(pass)
        
        if let sceneRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: sceneRenderDescriptor){
            sceneRenderEncoder.label = "MySceneRenderEncoder"
            
            if let frame = currentFrame {
                drawVideoQuad(frame, viewPortSize: view.bounds.size, sceneRenderEncoder: sceneRenderEncoder)
            }
            
            let viewMatrix = pointOfView.worldTransform.matrix
            let projectionMatrix = camera.projectionTransform
            
            frameUniforms = FrameUniforms()
            frameUniforms!.viewMatrix = viewMatrix
            frameUniforms!.viewProjectionMatrix = projectionMatrix * viewMatrix

            sceneRenderEncoder.setVertexBytes(&frameUniforms, length: MemoryLayout.size(ofValue: frameUniforms), index: 1)
            
            let nodes = visibleNodes(in: scene, from: pointOfView)
            for node in nodes {
                drawNode(node, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix, sceneRenderEncoder: sceneRenderEncoder)
            }
            sceneRenderEncoder.endEncoding()
        }
        
        //Perform final composite pass
        if let compositeRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) {
            compositeRenderEncoder.label = "MyCompositeRenderEncoder"
            if let frame = currentFrame {
                // Composite images to final render targets
                compositeImagesWithEncoder(frame: frame, viewPortSize: view.bounds.size, renderEncoder: compositeRenderEncoder)
            }
            compositeRenderEncoder.endEncoding()
        }
        
        // Schedule a drawable presentation once the framebuffer is complete using the current drawable
        guard let drawable = view.currentDrawable else { return }
        commandBuffer.present(drawable)
        
       
        let texture = drawable.texture
               commandBuffer.addScheduledHandler { commandBuffer in
                self.recorder!.writeFrame(forTexture: texture)
               }
        
        let deltaTime = 1 / Float(15)
        scene.update(deltaTime: deltaTime)
        
        endFrame()
    }
    
    public func beginFrame() {
        commandBuffer = Engine.commandQueue.makeCommandBuffer()
        GameTime.UpdateTime(1/60)
        instanceUniformBuffer = bufferAllocator.dequeueReusableBuffer(length: 64 * 256)
        instanceUniformBufferOffset = 0
    }
    
    // Create render targets for offscreen camera image and scene render
    func configureMatteRenderTargets(view: MTKView){
        //Matte
        let width = view.currentDrawable!.texture.width
        let height = view.currentDrawable!.texture.height
        
        let colorDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.MainPixelFormat, width: width, height: height, mipmapped: false)
        colorDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        sceneColorTexture = device.makeTexture(descriptor: colorDescriptor)
        
        let depthDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.MainDepthPixelFormat,
                                                                 width: width, height: height, mipmapped: false)
        depthDesc.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        sceneDepthTexture = device.makeTexture(descriptor: depthDesc)
    }
    
    func updateMatteTextures(){
        guard let currentFrame = session?.currentFrame else { return }
        alphaTexture = matteGenerator.generateMatte(from: currentFrame, commandBuffer: commandBuffer)
        dilatedDepthTexture = matteGenerator.generateDilatedDepth(from: currentFrame, commandBuffer: commandBuffer)
    }
    
    //MATTE: Setup offscreen renderpass for later compositing
    func setUpOffscreenRenderPass(_ pass: MTLRenderPassDescriptor) -> MTLRenderPassDescriptor{
        guard let sceneRenderDescriptor = pass.copy() as? MTLRenderPassDescriptor else {
            fatalError("Unable to create a render pass descriptor.")
        }
        sceneRenderDescriptor.colorAttachments[0].texture = sceneColorTexture
        sceneRenderDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        sceneRenderDescriptor.colorAttachments[0].loadAction = .clear
        sceneRenderDescriptor.colorAttachments[0].storeAction = .store
        
        sceneRenderDescriptor.depthAttachment.texture = sceneDepthTexture
        sceneRenderDescriptor.depthAttachment.clearDepth = 1.0
        sceneRenderDescriptor.depthAttachment.loadAction = .clear
        sceneRenderDescriptor.depthAttachment.storeAction = .store
        
        return sceneRenderDescriptor
    }
    
    public func drawVideoQuad(_ frame: ARFrame, viewPortSize: CGSize, sceneRenderEncoder: MTLRenderCommandEncoder){
        let pixelBuffer = frame.capturedImage
        
        var lumaTexture: CVMetalTexture? = nil
        let lumaWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let lumaHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, .r8Unorm, lumaWidth, lumaHeight, 0, &lumaTexture)
        
        var chromaTexture: CVMetalTexture? = nil
        let chromaWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1)
        let chromaHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
        CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, .rg8Unorm, chromaWidth, chromaHeight, 1, &chromaTexture)
        
        if let lumaTex = lumaTexture, let chromaTex = chromaTexture {
            self.luma = lumaTex
            self.chroma = chromaTex
            
            let renderPipelineState = RenderPipelineStateLibrary.PipelineState(.Video)
            sceneRenderEncoder.setRenderPipelineState(renderPipelineState)
            sceneRenderEncoder.setDepthStencilState(DepthStencilStateLibrary.DepthStencilState(.Quad))
            
            sceneRenderEncoder.setVertexBytes(vertices, length: MemoryLayout<Float>.size * 16, index: 0)
            
            let transform = frame.displayTransform(for: interfaceOrientation, viewportSize: viewPortSize)
            var transformMatrix = float3x3(affineTransform: transform).inverse
            sceneRenderEncoder.setVertexBytes(&transformMatrix, length: MemoryLayout.size(ofValue: transformMatrix), index: 1)
        
            sceneRenderEncoder.setFragmentTexture(CVMetalTextureGetTexture(luma!), index: 0)
            sceneRenderEncoder.setFragmentTexture(CVMetalTextureGetTexture(chroma!), index: 1)
            
            sceneRenderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            
            //MATTE
            scenePlaneVertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Float>.size * 16, options: [])
            imagePlaneVertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Float>.size * 16, options: [])
        }
    }
    
    public func endFrame() {
        let uniformBuffer: MTLBuffer = instanceUniformBuffer
        commandBuffer.addScheduledHandler{ _ in
            self.bufferAllocator.enqueueReusableBuffer(uniformBuffer)
        }
        commandBuffer.commit()
    }
    
    private func drawNode(_ node: Node, viewMatrix: float4x4, projectionMatrix: float4x4, sceneRenderEncoder: MTLRenderCommandEncoder){
        guard let geometry = node.geometry else { return }
        
        var materialCheck = node.geometry?.materialCheck
        
        let renderPipelineState = RenderPipelineStateLibrary.PipelineState(.Basic)
        sceneRenderEncoder.setRenderPipelineState(renderPipelineState)
        sceneRenderEncoder.setDepthStencilState(DepthStencilStateLibrary.DepthStencilState(.Less))
        
        //Vertex Shader
        sceneRenderEncoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        //FragmentShader
        sceneRenderEncoder.setFragmentSamplerState(Entities.SamplerStates[.Linear], index: 0)
        sceneRenderEncoder.setFragmentBytes(&materialCheck, length: MaterialCheck.stride, index: 1)
         
        if(materialCheck!.useTexture){
             sceneRenderEncoder.setFragmentTexture(Entities.Textures[geometry._textureType], index: 0)
         }
        geometry.mesh.drawPrimitives(sceneRenderEncoder)
    }
    
    public func visibleNodes(in scene: Scene, from pointOfView: Node) -> [Node]{
        var nodes = [Node]()
        var queue = [scene.rootNode]
        
        while queue.count > 0 {
            let node = queue.removeFirst()
            if node.geometry != nil {
                nodes.append(node)
            }
            queue.append(contentsOf: node.childNodes)
        }
        return nodes
    }
    
    func compositeImagesWithEncoder(frame: ARFrame, viewPortSize: CGSize, renderEncoder: MTLRenderCommandEncoder) {
        guard let textureY = luma, let textureCbCr = chroma else {
            return
        }

        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
        renderEncoder.pushDebugGroup("CompositePass")

        // Set render command encoder state
        renderEncoder.setCullMode(.none)
        renderEncoder.setRenderPipelineState(RenderPipelineStateLibrary.PipelineState(.Composite))
        renderEncoder.setDepthStencilState(DepthStencilStateLibrary.DepthStencilState(.Composite))

        // Setup plane vertex buffers
        renderEncoder.setVertexBytes(vertices, length: MemoryLayout<Float>.size * 16, index: 0)
        renderEncoder.setVertexBuffer(scenePlaneVertexBuffer, offset: 0, index: 1)
        
        let transform = frame.displayTransform(for: interfaceOrientation, viewportSize: viewPortSize)
        var transformMatrix = float3x3(affineTransform: transform).inverse
        renderEncoder.setVertexBytes(&transformMatrix, length: MemoryLayout.size(ofValue: transformMatrix), index: 2)
        
        
        // Setup textures for the composite fragment shader
        renderEncoder.setFragmentBytes(&frameUniforms, length: MemoryLayout.size(ofValue: frameUniforms), index: 1)
        renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureY), index: 0)
        renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureCbCr), index: 1)
        renderEncoder.setFragmentTexture(sceneColorTexture, index: 2)
        renderEncoder.setFragmentTexture(sceneDepthTexture, index: 3)
        renderEncoder.setFragmentTexture(alphaTexture, index: 4)
        renderEncoder.setFragmentTexture(dilatedDepthTexture, index: 5)

        // Draw final quad to display
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.popDebugGroup()
    }
    
    public func isNode(_ node: Node, insideFrustumOf pointOfView: Node) -> Bool {
        return true
    }
        
    public func nodesInsideFrustum(of pointOfView: Node) -> [Node] {
        return []
    }
        
    public func projectPoint(_ point: SIMD3<Float>) -> SIMD3<Float> {
        guard let frameCamera = currentFrame?.camera else { return point }
        let viewMatrix: matrix_float4x4 = frameCamera.viewMatrix(for: interfaceOrientation)
        let projectionMatrix: matrix_float4x4 = frameCamera.projectionMatrix(for: interfaceOrientation,
                                                                            viewportSize: drawableSize, zNear: 0.01, zFar: 100)
        let viewProjectionMatrix = projectionMatrix * viewMatrix
        return (viewProjectionMatrix * SIMD4<Float>(point, 1)).xyz
    }
        
    public func unprojectPoint(_ point: SIMD3<Float>) -> SIMD3<Float> {
            return SIMD3<Float>(0,0,0)
    }
    
     
}

