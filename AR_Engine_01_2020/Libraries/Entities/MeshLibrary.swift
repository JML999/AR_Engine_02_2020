import MetalKit

enum MeshTypes {
    case Triangle_Custom
    case Quad_Custom
    case Cube_Custom
    case Cruiser
    
    case VerticalSegment
    case HorizontalSegment
}

class MeshLibrary: Library<MeshTypes, Mesh> {
    
    private var _library: [MeshTypes:Mesh] = [:]
    
    override func fillLibrary() {
        _library.updateValue(Triangle_CustomMesh(), forKey: .Triangle_Custom)
        _library.updateValue(Quad_CustomMesh(), forKey: .Quad_Custom)
        _library.updateValue(Cube_CustomMesh(), forKey: .Cube_Custom)
        
        _library.updateValue(VerticalSegment_CustomMesh(), forKey: .VerticalSegment)
        _library.updateValue(HorizontalSegment_CustomMesh(), forKey: .HorizontalSegment)
        
        _library.updateValue(ModelMesh(modelName: "cruiser"), forKey: .Cruiser)
    }
    
    override subscript(_ type: MeshTypes)->Mesh {
        return _library[type]!
    }
    
}

protocol Mesh {
    func setInstanceCount(_ count: Int)
    func drawPrimitives(_ renderCommandEncoder: MTLRenderCommandEncoder)
}

class ModelMesh: Mesh {
    private var _meshes: [Any]!
    private var _instanceCount: Int = 1
    
    init(modelName: String){
        loadModel(modelName: modelName)
    }
    
    func loadModel(modelName: String){
        guard let assetURL = Bundle.main.url(forResource: modelName, withExtension: "obj") else {
            fatalError("Asset \(modelName) does not exist")
        }
        
        let descriptor = MTKModelIOVertexDescriptorFromMetal(VertexDescriptorLibrary.Descriptor(.Basic))
        (descriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (descriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeColor
        (descriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        
        let bufferAllocator = MTKMeshBufferAllocator(device: Engine.Device)
        let asset: MDLAsset = MDLAsset(url: assetURL, vertexDescriptor: descriptor, bufferAllocator: bufferAllocator)
        do {
            self._meshes = try MTKMesh.newMeshes(asset: asset, device: Engine.Device).metalKitMeshes
        } catch {
            print("ERROR::LOADING_MESH::_\(modelName)_::\(error)")
        }
    }
    
    func setInstanceCount(_ count: Int) {
        self._instanceCount = count
    }
    
    func drawPrimitives(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        guard let meshes = self._meshes as? [MTKMesh] else { return }
        for mesh in meshes {
            for vertexBuffer in mesh.vertexBuffers {
                renderCommandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
                for submesh in mesh.submeshes {
                    renderCommandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                               indexCount: submesh.indexCount,
                                                               indexType: submesh.indexType,
                                                               indexBuffer: submesh.indexBuffer.buffer,
                                                               indexBufferOffset: submesh.indexBuffer.offset,
                                                               instanceCount: self._instanceCount)
                }
            }
        }
    }
}

class CustomMesh: Mesh {
    private var _vertices: [Vertex] = []
    private var _vertexBuffer: MTLBuffer!
    private var _instanceCount: Int = 1
    
    var vertexCount: Int! {
        return _vertices.count
    }
    
    
    init() {
        createVertices()
        createBuffers()
    }
    
    func createVertices(){ }
    
    func createBuffers(){
        _vertexBuffer = Engine.Device.makeBuffer(bytes: _vertices,
                                                length: Vertex.stride(vertexCount),
                                                options: [])
    }
    
    func addVertex(position: SIMD3<Float>,
                   color: SIMD4<Float> = SIMD4<Float>(1,0,1,1),
                   textureCoordinate: SIMD2<Float> = SIMD2<Float>(0,0)) {
        _vertices.append(Vertex(position: position, color: color, textureCoordinate: textureCoordinate))
    }
    
    func setInstanceCount(_ count: Int) {
        self._instanceCount = count
    }
    
    
    func drawPrimitives(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setVertexBuffer(_vertexBuffer, offset: 0,
                                             index: 0)
        
        renderCommandEncoder.drawPrimitives(type: .triangle,
                                            vertexStart: 0,
                                            vertexCount: vertexCount,
                                            instanceCount: _instanceCount)
    }
    
}

class Triangle_CustomMesh: CustomMesh {
    override func createVertices() {
        addVertex(position: SIMD3<Float>( 0, 1,0), color: SIMD4<Float>(1,0,0,1))
        addVertex(position: SIMD3<Float>(-1,-1,0), color: SIMD4<Float>(0,1,0,1))
        addVertex(position: SIMD3<Float>( 1,-1,0), color: SIMD4<Float>(0,0,1,1))
    }
}

class Quad_CustomMesh: CustomMesh {
    override func createVertices() {
        addVertex(position: SIMD3<Float>( 5, 3,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(1,0)) //Top Right
        addVertex(position: SIMD3<Float>(-5, 3,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(0,0)) //Top Left
        addVertex(position: SIMD3<Float>(-5,-3,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(0,1)) //Bottom Left
        
        addVertex(position: SIMD3<Float>( 5, 3,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(1,0)) //Top Right
        addVertex(position: SIMD3<Float>(-5,-3,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(0,1)) //Bottom Left
        addVertex(position: SIMD3<Float>( 5,-3,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(1,1)) //Bottom Right
    }
}

class Cube_CustomMesh: CustomMesh {
    override func createVertices() {
        //Left
        addVertex(position: SIMD3<Float>(-1.0,-1.0,-1.0), color: SIMD4<Float>(1.0, 0.5, 0.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0,-1.0, 1.0), color: SIMD4<Float>(0.0, 1.0, 0.5, 1.0))
        addVertex(position: SIMD3<Float>(-1.0, 1.0, 1.0), color: SIMD4<Float>(0.0, 0.5, 1.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0,-1.0,-1.0), color: SIMD4<Float>(1.0, 1.0, 0.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0, 1.0, 1.0), color: SIMD4<Float>(0.0, 1.0, 1.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0, 1.0,-1.0), color: SIMD4<Float>(1.0, 0.0, 1.0, 1.0))
        
        //RIGHT
        addVertex(position: SIMD3<Float>( 1.0, 1.0, 1.0), color: SIMD4<Float>(1.0, 0.0, 0.5, 1.0))
        addVertex(position: SIMD3<Float>( 1.0,-1.0,-1.0), color: SIMD4<Float>(0.0, 1.0, 0.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0, 1.0,-1.0), color: SIMD4<Float>(0.0, 0.5, 1.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0,-1.0,-1.0), color: SIMD4<Float>(1.0, 1.0, 0.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0, 1.0, 1.0), color: SIMD4<Float>(0.0, 1.0, 1.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0,-1.0, 1.0), color: SIMD4<Float>(1.0, 0.5, 1.0, 1.0))
        
        //TOP
        addVertex(position: SIMD3<Float>( 1.0, 1.0, 1.0), color: SIMD4<Float>(1.0, 0.0, 0.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0, 1.0,-1.0), color: SIMD4<Float>(0.0, 1.0, 0.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0, 1.0,-1.0), color: SIMD4<Float>(0.0, 0.0, 1.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0, 1.0, 1.0), color: SIMD4<Float>(1.0, 1.0, 0.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0, 1.0,-1.0), color: SIMD4<Float>(0.5, 1.0, 1.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0, 1.0, 1.0), color: SIMD4<Float>(1.0, 0.0, 1.0, 1.0))
        
        //BOTTOM
        addVertex(position: SIMD3<Float>( 1.0,-1.0, 1.0), color: SIMD4<Float>(1.0, 0.5, 0.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0,-1.0,-1.0), color: SIMD4<Float>(0.5, 1.0, 0.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0,-1.0,-1.0), color: SIMD4<Float>(0.0, 0.0, 1.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0,-1.0, 1.0), color: SIMD4<Float>(1.0, 1.0, 0.5, 1.0))
        addVertex(position: SIMD3<Float>(-1.0,-1.0, 1.0), color: SIMD4<Float>(0.0, 1.0, 1.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0,-1.0,-1.0), color: SIMD4<Float>(1.0, 0.5, 1.0, 1.0))
        
        //BACK
        addVertex(position: SIMD3<Float>( 1.0, 1.0,-1.0), color: SIMD4<Float>(1.0, 0.5, 0.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0,-1.0,-1.0), color: SIMD4<Float>(0.5, 1.0, 0.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0, 1.0,-1.0), color: SIMD4<Float>(0.0, 0.0, 1.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0, 1.0,-1.0), color: SIMD4<Float>(1.0, 1.0, 0.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0,-1.0,-1.0), color: SIMD4<Float>(0.0, 1.0, 1.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0,-1.0,-1.0), color: SIMD4<Float>(1.0, 0.5, 1.0, 1.0))
        
        //FRONT
        addVertex(position: SIMD3<Float>(-1.0, 1.0, 1.0), color: SIMD4<Float>(1.0, 0.5, 0.0, 1.0))
        addVertex(position: SIMD3<Float>(-1.0,-1.0, 1.0), color: SIMD4<Float>(0.0, 1.0, 0.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0,-1.0, 1.0), color: SIMD4<Float>(0.5, 0.0, 1.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0, 1.0, 1.0), color: SIMD4<Float>(1.0, 1.0, 0.5, 1.0))
        addVertex(position: SIMD3<Float>(-1.0, 1.0, 1.0), color: SIMD4<Float>(0.0, 1.0, 1.0, 1.0))
        addVertex(position: SIMD3<Float>( 1.0,-1.0, 1.0), color: SIMD4<Float>(1.0, 0.0, 1.0, 1.0))
    }

}

class VerticalSegment_CustomMesh: CustomMesh {
    
    public var width: Float = 0.009
    public var length: Float = 0.025
    
    override func createVertices() {
        addVertex(position: SIMD3<Float>( width, length,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(1,0)) //Top Right
        addVertex(position: SIMD3<Float>(-width, length,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(0,0)) //Top Left
        addVertex(position: SIMD3<Float>(-width,-length,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(0,1)) //Bottom Left
        
        addVertex(position: SIMD3<Float>( width, length,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(1,0)) //Top Right
        addVertex(position: SIMD3<Float>(-width,-length,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(0,1)) //Bottom Left
        addVertex(position: SIMD3<Float>( width,-length,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(1,1)) //Bottom Right
    }
}

class HorizontalSegment_CustomMesh: CustomMesh {
    
    var width: Float = 0.025
    var length: Float = 0.009
    
    override func createVertices() {
        addVertex(position: SIMD3<Float>( width, length,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(1,0)) //Top Right
        addVertex(position: SIMD3<Float>(-width, length,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(0,0)) //Top Left
        addVertex(position: SIMD3<Float>(-width,-length,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(0,1)) //Bottom Left
        
        addVertex(position: SIMD3<Float>( width, length,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(1,0)) //Top Right
        addVertex(position: SIMD3<Float>(-width,-length,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(0,1)) //Bottom Left
        addVertex(position: SIMD3<Float>( width,-length,0), color: SIMD4<Float>(0.9,1,0,1), textureCoordinate: SIMD2<Float>(1,1)) //Bottom Right
    }

}

class PlaneMesh: Mesh {
    
    private var _vertexBuffer: MTLBuffer!
    private var _instanceCount: Int = 1
    public var vCount: Int!
    
    private struct Vertex {
        var position: packed_float3
        var normal: packed_float3
        var texCoords: packed_float2
    }
    
     init(vertices: [SIMD3<Float>], texCoords: [SIMD2<Float>], indices:[Int16], bufferAllocator: BufferAllocator) {
        createBuffers(vertices: vertices, texCoords: texCoords, indices: indices, bufferAllocator: bufferAllocator)
    }
    
    func createBuffers(vertices: [SIMD3<Float>], texCoords: [SIMD2<Float>], indices:[Int16], bufferAllocator: BufferAllocator) {
        let vertexBuffer = bufferAllocator.makeBuffer(length: MemoryLayout<Vertex>.stride * vertices.count)
        let verticesPtr = vertexBuffer.contents().assumingMemoryBound(to: Vertex.self)
        
        assert(indices.count > 2)
        
        let v0 = vertices[Int(indices[0])]
        let v1 = vertices[Int(indices[1])]
        let v2 = vertices[Int(indices[2])]
        let v10 = v1 - v0
        let v20 = v2 - v0
        let normal = normalize(simd_cross(v10, v20))
        
        for i in 0..<vertices.count {
            verticesPtr[i].position = packed_float3(vertices[i])
            verticesPtr[i].normal = packed_float3(normal)
            verticesPtr[i].texCoords = texCoords[i]
        }
        
        self._vertexBuffer = vertexBuffer
        self.vCount = vertices.count
    }
    
    func drawPrimitives(_ renderCommandEncoder: MTLRenderCommandEncoder) {
           renderCommandEncoder.setVertexBuffer(_vertexBuffer, offset: 0,
                                                index: 0)
           
           renderCommandEncoder.drawPrimitives(type: .triangle,
                                               vertexStart: 0,
                                               vertexCount: vCount,
                                               instanceCount: _instanceCount)
       }
    
    func setInstanceCount(_ count: Int) {
        self._instanceCount = count
    }
}


