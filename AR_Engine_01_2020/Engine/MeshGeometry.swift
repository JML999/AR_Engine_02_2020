import MetalKit
import Metal

class MeshGeometry: Geometry {
    private var _vertices: [Vertex] = []
    private var _vertexBuffer: MTLBuffer!
    
    init(meshType: MeshTypes) {
        let descriptor = VertexDescriptorLibrary.Descriptor(.Basic)
        super.init(buffers: [], elements: [], vertexDescriptor: descriptor)
        super.mesh = Entities.Meshes[meshType]
    }
}
