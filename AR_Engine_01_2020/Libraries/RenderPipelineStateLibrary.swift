import MetalKit

enum RenderPipelineStateTypes {
    case Basic
    case Video
    case Composite
}

class RenderPipelineStateLibrary {
    
    private static var renderPipelineStates: [RenderPipelineStateTypes: RenderPipelineState] = [:]
    
    public static func Initialize(){
        createDefaultRenderPipelineStates()
    }
    
    private static func createDefaultRenderPipelineStates(){
        renderPipelineStates.updateValue(Basic_RenderPipelineState(), forKey: .Basic)
        renderPipelineStates.updateValue(VideoQuad_RenderPipelineState(), forKey: .Video)
        renderPipelineStates.updateValue(Composite_RenderPipelineState(), forKey: .Composite)
    }
    
    public static func PipelineState(_ renderPipelineStateType: RenderPipelineStateTypes)->MTLRenderPipelineState{
        return (renderPipelineStates[renderPipelineStateType]?.renderPipelineState)!
    }
    
}

protocol RenderPipelineState {
    var name: String { get }
    var renderPipelineState: MTLRenderPipelineState! { get }
}

public struct Basic_RenderPipelineState: RenderPipelineState {
    var name: String = "Basic Render Pipeline State"
    var renderPipelineState: MTLRenderPipelineState!
    init(){
        do{
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: RenderPipelineDescriptorLibrary.Descriptor(.Basic))
        }catch let error as NSError {
            print("ERROR::CREATE::RENDER_PIPELINE_STATE::__\(name)__::\(error)")
        }
    }
}

public struct VideoQuad_RenderPipelineState: RenderPipelineState {
    var name: String = "Video Quad Pipeline State"
    var renderPipelineState: MTLRenderPipelineState!
    init(){
        do{
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: RenderPipelineDescriptorLibrary.Descriptor(.Video))
        }catch let error as NSError {
            print("ERROR::CREATE::RENDER_PIPELINE_STATE::__\(name)__::\(error)")
        }
    }
}


public struct Composite_RenderPipelineState: RenderPipelineState {
    var name: String = "Anchor Pipeline State"
    var renderPipelineState: MTLRenderPipelineState!
    init(){
        do{
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: RenderPipelineDescriptorLibrary.Descriptor(.Composite))
        }catch let error as NSError {
            print("ERROR::CREATE::RENDER_PIPELINE_STATE::__\("Anchor")__::\(error)")
        }
    }
}

