import MetalKit

enum VertexDescriptorTypes {
    case Basic
    case Video
    case Geometry
}

class VertexDescriptorLibrary {
    private static var vertexDescriptors: [VertexDescriptorTypes: VertexDescriptor] = [:]
    
    public static func Intialize(){
        createDefaultVertexDescriptors()
    }
    
    private static func createDefaultVertexDescriptors(){
        vertexDescriptors.updateValue(Basic_VertexDescriptor(), forKey: .Basic)
        vertexDescriptors.updateValue(VideoQuad_VertexDescriptor(), forKey: .Video)
        vertexDescriptors.updateValue(Geometry_VertexDescriptor(), forKey: .Geometry)
    }
    
    public static func Descriptor(_ vertexDescriptorType: VertexDescriptorTypes)->MTLVertexDescriptor{
        return vertexDescriptors[vertexDescriptorType]!.vertexDescriptor
    }
}

protocol VertexDescriptor {
    var name: String { get }
    var vertexDescriptor: MTLVertexDescriptor! { get }
}

public struct Basic_VertexDescriptor: VertexDescriptor{
    var name: String = "Basic Vertex Descriptor"
    
    var vertexDescriptor: MTLVertexDescriptor!
    init(){
        vertexDescriptor = MTLVertexDescriptor()
        
        //Position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        //Color
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = float3.size
        
        //Texture Coordinate
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].offset = float3.size + float4.size
        
         /*
        //Normal
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.stride * 3
        
        //Texture
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.stride * 6
        
       
        //Color
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 3
        */
        
        vertexDescriptor.layouts[0].stride = Vertex.stride
    }
}

public struct VideoQuad_VertexDescriptor: VertexDescriptor{
    var name: String = "Video Quad Vertex Descriptor"
    
    var vertexDescriptor: MTLVertexDescriptor!
    init(){
        vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 4
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stepRate = 1
    }
}

public struct Geometry_VertexDescriptor: VertexDescriptor{
    var name: String = "Geometry Vertex Descriptor"
    
    var vertexDescriptor: MTLVertexDescriptor!
    init(){
        vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = 0
        vertexDescriptor.attributes[1].bufferIndex = 1
        
        vertexDescriptor.attributes[2].format = .half3
        vertexDescriptor.attributes[2].offset = 8
        vertexDescriptor.attributes[2].bufferIndex = 1
        
        vertexDescriptor.layouts[0].stride = 12
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        vertexDescriptor.layouts[1].stride = 16
        vertexDescriptor.layouts[1].stepRate = 1
        vertexDescriptor.layouts[1].stepFunction = .perVertex
    }
}
