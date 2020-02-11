import Foundation
import MetalKit

open class BufferAllocator {
    public var device: MTLDevice
    private var allocationQueue = DispatchQueue(label: "com.metalbyexample.alloc-queue")
    private var pool: [MTLBuffer]
    
    let VertexTR =  SIMD3<Float>(1,1,0)
    let VertexTL =  SIMD3<Float>(-1,1,0)
    let VertexBL =  SIMD3<Float>(-1,-1,0)
    let VertexTR2 =  SIMD3<Float>(1,1,0)
    let VertexBL2 =  SIMD3<Float>(-1,-1,0)
    let VertexBR =  SIMD3<Float>(1,-1,0)
    
    let TextureTR =  SIMD2<Float>(1,0)
    let TextureTL =  SIMD2<Float>(0,0)
    let TextureBL =  SIMD2<Float>(0,1)
    let TextureTR2 = SIMD2<Float>(1,0)
    let TextureBL2 = SIMD2<Float>(0,1)
    let TextureBR =  SIMD2<Float>(1,1)
    
    var vertices: [SIMD3<Float>]!
    var textures: [SIMD2<Float>]!
    var indicies: [Int16]!
    
    public init (device: MTLDevice){
        self.device = device
        pool = []
        
        vertices = [
            VertexTR,
            VertexTL,
            VertexBL,
            VertexTR2,
            VertexBL2,
            VertexBR
        ]
        
        textures = [
                   TextureTR,
                   TextureTL,
                   TextureBL,
                   TextureTR2,
                   TextureBL2,
                   TextureBR
        ]
        
        indicies = [
                   0,1,2,
                   0,2,3
        ]
    }
    
    public func dequeueReusableBuffer(length: Int)->MTLBuffer {
        var removedIndex: Int? = nil
        var buffer: MTLBuffer? = nil
        
        return allocationQueue.sync {
            for i in 0..<pool.count{
                if pool[i].length >= length{
                    buffer = pool[i]
                    removedIndex = i
                }
            }
            
            if let index = removedIndex, let buffer = buffer{
                pool.remove(at: index)
                return buffer
            }

            return makeBuffer(length: length)
        }
    }
    
    public func makeBuffer(length: Int)->MTLBuffer{
        return device.makeBuffer(length: length, options: .storageModeShared)!
    }
    
    public func makeCustomBuffer()->MTLBuffer {
        return device.makeBuffer(bytes: vertices, length: vertices.count, options: [])!
    }
    
   
    public func enqueueReusableBuffer(_ buffer: MTLBuffer){
        allocationQueue.sync {
            pool.append(buffer)
        }
    }
    
}
