import MetalKit
import ARKit
import simd

class SceneGameObject: Node {
    
    var modelConstants = ModelConstants()
    
    var mesh: Mesh!
    
    init(meshType: MeshTypes) {
        super.init()
   //     mesh = MeshLibrary.Mesh(meshType)
    }
    
    
   override func update(deltaTime: Float){
        updateModelConstants()
    }
    
    private func updateModelConstants(){
        
    }
    
}

extension SceneGameObject: SceneRenderable{
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStateLibrary.PipelineState(.Basic))
        renderCommandEncoder.setDepthStencilState(DepthStencilStateLibrary.DepthStencilState(.Less))
    //    renderCommandEncoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
        renderCommandEncoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
    //  renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.vertexCount)
        mesh.drawPrimitives(renderCommandEncoder)
    }
}
