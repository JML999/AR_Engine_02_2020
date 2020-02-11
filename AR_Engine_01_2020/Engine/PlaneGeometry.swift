import MetalKit
import Metal

class PlaneGeometry: Geometry {

    init(vertices: [SIMD3<Float>], texCoords: [SIMD2<Float>], indices: [Int16], bufferAllocator: BufferAllocator) {
        let descriptor = VertexDescriptorLibrary.Descriptor(.Basic)
        super.init(buffers: [], elements: [], vertexDescriptor: descriptor)
        super.mesh = PlaneMesh(vertices: vertices, texCoords: texCoords, indices: indices, bufferAllocator: bufferAllocator)
    }
}

