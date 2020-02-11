import MetalKit

enum TextureTypes{
    case None
    case flower
    case Cruiser
    
    case frame1
    case frame2
    case frame3
    case frame4
    case frame5
    case frame6
    case frame7
    case frame8
    case frame9
}

class TextureLibrary: Library<TextureTypes, MTLTexture> {
    private var library: [TextureTypes : Texture] = [:]
    
    override func fillLibrary() {
        library.updateValue(Texture("flower"), forKey: .flower)
        library.updateValue(Texture("cruiser", ext: "bmp", origin: .bottomLeft), forKey: .Cruiser)
        
        //Muybridge
        library.updateValue(Texture("frame1", ext: "png", origin: .topLeft), forKey: .frame1)
        library.updateValue(Texture("frame2", ext: "png", origin: .topLeft), forKey: .frame2)
        library.updateValue(Texture("frame3", ext: "png", origin: .topLeft), forKey: .frame3)
        library.updateValue(Texture("frame4", ext: "png", origin: .topLeft), forKey: .frame4)
        library.updateValue(Texture("frame5", ext: "png", origin: .topLeft), forKey: .frame5)
        library.updateValue(Texture("frame6", ext: "png", origin: .topLeft), forKey: .frame6)
        library.updateValue(Texture("frame7", ext: "png", origin: .topLeft), forKey: .frame7)
        library.updateValue(Texture("frame8", ext: "png", origin: .topLeft), forKey: .frame8)
        library.updateValue(Texture("frame9", ext: "png", origin: .topLeft), forKey: .frame9)
    }
    
    override subscript(_ type: TextureTypes) -> MTLTexture? {
        return library[type]?.texture
    }
}

class Texture {
    var texture: MTLTexture!
    
    init(_ textureName: String, ext: String = "jpg", origin: MTKTextureLoader.Origin = .topLeft){
        let textureLoader = TextureLoader(textureName: textureName, textureExtension: ext, origin: origin)
        let texture: MTLTexture = textureLoader.loadTextureFromBundle()
        setTexture(texture)
    }
    
    func setTexture(_ texture: MTLTexture){
        self.texture = texture
    }
}

class TextureLoader {
    private var _textureName: String!
    private var _textureExtension: String!
    private var _origin: MTKTextureLoader.Origin!
    
    init(textureName: String, textureExtension: String = "jpg", origin: MTKTextureLoader.Origin = .topLeft){
        self._textureName = textureName
        self._textureExtension = textureExtension
        self._origin = origin
    }
    
    public func loadTextureFromBundle()->MTLTexture{
        var result: MTLTexture!
        if let url = Bundle.main.url(forResource: _textureName, withExtension: self._textureExtension) {
            let textureLoader = MTKTextureLoader(device: Engine.Device)
            
            let options: [MTKTextureLoader.Option : MTKTextureLoader.Origin] = [MTKTextureLoader.Option.origin : _origin]
            
            do{
                result = try textureLoader.newTexture(URL: url, options: options)
                result.label = _textureName
            }catch let error as NSError {
                print("ERROR::CREATING::TEXTURE::__\(_textureName!)__::\(error)")
            }
        }else {
            print("ERROR::CREATING::TEXTURE::__\(_textureName!) does not exist")
        }
        
        return result
    }
}
