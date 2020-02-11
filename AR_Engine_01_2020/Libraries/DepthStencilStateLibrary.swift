import MetalKit

enum DepthStencilStateTypes {
    case Less
    case Quad
    case Composite
}

class DepthStencilStateLibrary {
    
    private static var _depthStencilStates: [DepthStencilStateTypes: DepthStencilState] = [:]
    
    public static func Intitialize(){
        createDefaultDepthStencilStates()
    }
    
    private static func createDefaultDepthStencilStates(){
        _depthStencilStates.updateValue(Less_DepthStencilState(), forKey: .Less)
        _depthStencilStates.updateValue(Quad_DepthStencilState(), forKey: .Quad)
        _depthStencilStates.updateValue(Composite_DepthStencilState(), forKey: .Composite)
    }
    
    public static func DepthStencilState(_ depthStencilStateType: DepthStencilStateTypes)->MTLDepthStencilState{
        return _depthStencilStates[depthStencilStateType]!.depthStencilState
    }
    
}

protocol DepthStencilState {
    var depthStencilState: MTLDepthStencilState! { get }
}

class Less_DepthStencilState: DepthStencilState {
    var depthStencilState: MTLDepthStencilState!
    init() {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilState = Engine.Device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
}

class Quad_DepthStencilState: DepthStencilState {
    var depthStencilState: MTLDepthStencilState!
    init() {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.isDepthWriteEnabled = false
        depthStencilDescriptor.depthCompareFunction = .always
        depthStencilState = Engine.Device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
}

class Composite_DepthStencilState: DepthStencilState {
    var depthStencilState: MTLDepthStencilState!
    init() {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.isDepthWriteEnabled = false
        depthStencilDescriptor.depthCompareFunction = .always
        depthStencilState = Engine.Device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
}
