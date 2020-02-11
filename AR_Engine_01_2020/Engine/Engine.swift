import MetalKit

class Engine {
    
    public static var Device: MTLDevice!
    public static var commandQueue: MTLCommandQueue!
    public var bufferAllocator: BufferAllocator!

    public static func Ignite(device: MTLDevice, bufferAllocator: BufferAllocator){
        self.Device = device
        self.commandQueue = device.makeCommandQueue()
            
        ShaderLibrary.Initialize()
        
        VertexDescriptorLibrary.Intialize()
        
        DepthStencilStateLibrary.Intitialize()
        
        RenderPipelineDescriptorLibrary.Initialize()
        
        RenderPipelineStateLibrary.Initialize()
        
        Entities.Initialize()
        
    }
    
}
