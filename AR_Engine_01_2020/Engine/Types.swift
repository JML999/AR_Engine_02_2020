import simd
import Metal
import MetalKit

protocol sizeable{ }
extension sizeable{
    static var size: Int{
        return MemoryLayout<Self>.size
    }
    
    static var stride: Int{
        return MemoryLayout<Self>.stride
    }
    
    static func size(_ count: Int)->Int{
        return MemoryLayout<Self>.size * count
    }
    
    static func stride(_ count: Int)->Int{
        return MemoryLayout<Self>.stride * count
    }
}

extension Float: sizeable {}
extension float3: sizeable {}
extension float4: sizeable {}

struct Vertex: sizeable{
    var position: SIMD3<Float>
    var color: SIMD4<Float>
    var textureCoordinate: SIMD2<Float>
}

struct ModelConstants: sizeable {
    var modelMatrix = matrix_identity_float4x4
}



struct FrameUniforms: sizeable {
//    var totalGameTime: Float = 0
    var viewMatrix = matrix_identity_float4x4
    var viewProjectionMatrix = matrix_identity_float4x4
}


struct MaterialCheck: sizeable{
    var color = SIMD4<Float>(0.8, 0.8, 0.8, 1.0)
    var useMaterialColor: Bool = false
    var useTexture: Bool = false
}

extension MTLTexture {

    func bytes() -> UnsafeMutableRawPointer {
        let width = self.width
        let height   = self.height
        let rowBytes = self.width * 4
        let p = malloc(width * height * 4)

        self.getBytes(p!, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)

        return p!
    }

    func toImage() -> CGImage? {
        let p = bytes()

        let pColorSpace = CGColorSpaceCreateDeviceRGB()

        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)

        let selftureSize = self.width * self.height * 4
        let rowBytes = self.width * 4
        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
            return
        }
        let provider = CGDataProvider(dataInfo: nil, data: p, size: selftureSize, releaseData: releaseMaskImagePixelData)
        let cgImageRef = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes, space: pColorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)!

        return cgImageRef
    }
}

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
    */
    var translation: SIMD3<Float> {
        get {
            let translation = columns.3
            return [translation.x, translation.y, translation.z]
        }
        set(newValue) {
            columns.3 = [newValue.x, newValue.y, newValue.z, columns.3.w]
        }
    }
    
    /**
     Factors out the orientation component of the transform.
    */
    var orientation: simd_quatf {
        return simd_quaternion(self)
    }
    
    /**
     Creates a transform matrix with a uniform scale factor in all directions.
     */
    init(uniformScale scale: Float) {
        self = matrix_identity_float4x4
        columns.0.x = scale
        columns.1.y = scale
        columns.2.z = scale
    }
}



