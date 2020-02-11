import MetalKit

enum VertexShaderTypes{
    case Basic
    case Video
    case Composite
    
}

enum FragmentShaderTypes {
    case Basic
    case Video
    case Composite
}

class ShaderLibrary {
    
    public static var DefaultLibrary: MTLLibrary!
    
    private static var vertexShaders: [VertexShaderTypes: Shader] = [:]
    private static var fragmentShaders: [FragmentShaderTypes: Shader] = [:]
    
    public static func Initialize(){
        DefaultLibrary = Engine.Device.makeDefaultLibrary()
        createDefaultShaders()
    }
    
    public static func createDefaultShaders(){
        //Vertex Shaders
        vertexShaders.updateValue(Basic_VertexShader(), forKey: .Basic)
        vertexShaders.updateValue(VideoQuad_VertexShader(), forKey: .Video)
        vertexShaders.updateValue(Composite_VertexShader(), forKey: .Composite)
        
        //Fragment Shaders
        fragmentShaders.updateValue(Basic_FragmentShader(), forKey: .Basic)
        fragmentShaders.updateValue(VideoQuad_FragmentShader(), forKey: .Video)
        fragmentShaders.updateValue(Composite_FragmentShader(), forKey: .Composite)
    }
    
    public static func Vertex(_ vertexShaderType: VertexShaderTypes)->MTLFunction{
        return vertexShaders[vertexShaderType]!.function
    }
    
    public static func Fragment(_ fragmentShaderType: FragmentShaderTypes)->MTLFunction{
        return fragmentShaders[fragmentShaderType]!.function
    }
    
}

protocol Shader{
    var name: String { get }
    var functionName: String { get }
    var function: MTLFunction! { get }
}

public struct Basic_VertexShader: Shader {
    public var name: String = "Basic Vertex Shader"
    public var functionName: String = "basic_vertex_shader"
    public var function: MTLFunction!
    init(){
        function = ShaderLibrary.DefaultLibrary.makeFunction(name: functionName)
        function?.label = name
    }
}

public struct Basic_FragmentShader: Shader {
    public var name: String = "Basic Fragment Shader"
    public var functionName: String = "basic_fragment_shader"
    public var function: MTLFunction!
    init(){
        function = ShaderLibrary.DefaultLibrary.makeFunction(name: functionName)
        function?.label = name
    }
}

public struct VideoQuad_VertexShader: Shader {
    public var name: String = "Video Quad Vertex Shader"
    public var functionName: String = "videoQuadVertex"
    public var function: MTLFunction!
    init(){
        function = ShaderLibrary.DefaultLibrary.makeFunction(name: functionName)
        function?.label = name
    }
}

public struct VideoQuad_FragmentShader: Shader {
    public var name: String = "Video Quad Fragment Shader"
    public var functionName: String = "videoQuadFragment"
    public var function: MTLFunction!
    init(){
        function = ShaderLibrary.DefaultLibrary.makeFunction(name: functionName)
        function?.label = name
    }
}

public struct Composite_VertexShader: Shader {
    public var name: String = "Composite Vertex Shader"
    public var functionName: String = "compositeImageVertexTransform"
    public var function: MTLFunction!
    init(){
        function = ShaderLibrary.DefaultLibrary.makeFunction(name: functionName)
        function?.label = name
    }
}

public struct Composite_FragmentShader: Shader {
    public var name: String = "Composite Fragment Shader"
    public var functionName: String = "compositeImageFragmentShader"
    public var function: MTLFunction!
    init(){
        function = ShaderLibrary.DefaultLibrary.makeFunction(name: functionName)
        function?.label = name
    }
}

