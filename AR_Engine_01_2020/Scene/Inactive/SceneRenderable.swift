import MetalKit

protocol SceneRenderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder)
}

