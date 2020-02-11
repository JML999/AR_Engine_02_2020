import MetalKit
import simd

enum SceneTypes {
    case sandbox
}

class SceneManager {
    
    private static var _currentScene: EntityNode?
    
    public static func Initialize(_ sceneType: SceneTypes, bufferAllocator: BufferAllocator){
        SetScene(sceneType, bufferAllocator: bufferAllocator)
    }
    
    
    public static func SetScene(_ sceneType: SceneTypes, bufferAllocator: BufferAllocator){
        switch sceneType {
        case .sandbox:
            _currentScene = Background(bufferAllocator: bufferAllocator)
        }
    }
    
    public static func TickScene(renderCommandEncoder: MTLRenderCommandEncoder, deltaTime: Float,
                                 viewMatrix: matrix_float4x4, projectionMatrix: matrix_float4x4){
        
        _currentScene!.setSceneConstants(viewMatrix: viewMatrix, projectionMatrix: projectionMatrix )
        _currentScene!.update(deltaTime: deltaTime)
        _currentScene!.render(renderCommandEncoder: renderCommandEncoder)
    }
}
