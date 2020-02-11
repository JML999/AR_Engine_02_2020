class Entities {
    
    private static var _meshLibrary: MeshLibrary!
    public static var Meshes: MeshLibrary { return _meshLibrary }
    
    private static var _textureLibrary: TextureLibrary!
    public static var Textures: TextureLibrary { return _textureLibrary }
    
    private static var _samplerStateLibrary: SamplerStateLibrary!
    public static var SamplerStates: SamplerStateLibrary { return _samplerStateLibrary }
    
    public static func Initialize() {
        self._textureLibrary = TextureLibrary()
        self._meshLibrary = MeshLibrary()
        self._samplerStateLibrary = SamplerStateLibrary()
    }
    
}
