import MetalKit
import simd

class EntityNode: Node {
    
    var frameUniforms = FrameUniforms()
    public var bufferAllocator: BufferAllocator?
    
    override init(bufferAllocator : BufferAllocator?){
        super.init()
        self.bufferAllocator = bufferAllocator
        buildScene()
    }
    
    func buildScene() { }
    
    func updateSceneConstants() {}
    
    func setSceneConstants(viewMatrix: matrix_float4x4, projectionMatrix: matrix_float4x4 ){
        frameUniforms.viewMatrix = viewMatrix
        frameUniforms.viewProjectionMatrix = projectionMatrix
    }
    
    override func update(deltaTime: Float) {

    }
    
    override func render(renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setVertexBytes(&frameUniforms, length: FrameUniforms.stride, index: 1)
        super.render(renderCommandEncoder: renderCommandEncoder)
    }
    

}

