@objc class SpriteFrame: NSObject {
    var texture: CCTexture {
        return _texture ?? lazyTexture
    }
    var _texture: CCTexture?
    var textureFilename: String = "" {
        didSet {
            // Make sure any previously loaded texture is cleared.
            self._texture = nil
            self._lazyTexture = nil
        }
    }
    var proxy: CCProxy {
        if _proxy == nil {
            _proxy = CCProxy(target: self)
        }
        return _proxy!
    }
    
    private var _proxy: CCProxy?
    var lazyTexture: CCTexture {
        if _lazyTexture == nil && textureFilename != "" {
            _lazyTexture = CCTextureCache.shared().addImage(textureFilename)
            _texture = _lazyTexture
        }
        return texture
    }
    private var _lazyTexture: CCTexture?
    
    /** Rectangle of the frame within the texture, in points. */
    var rect: CGRect
    /** If YES, the frame rectangle is rotated. */
    var rotated: Bool
    /** To save space in a spritesheet, the transparent edges of a frame may be trimmed. This is the original size in points of a frame before it was trimmed. */
    var untrimmedSize: CGSize
    /** To save space in a spritesheet, the transparent edges of a frame may be trimmed. This is offset of the sprite caused by trimming in points. */
    var trimOffset: CGPoint
    
    static func frameWithImageNamed(_ imageName: String) -> SpriteFrame! {
        return CCSpriteFrameCache.shared().spriteFrame(byName: imageName)
    }
    
    init(texture: CCTexture!, rect: CGRect, rotated: Bool, trimOffset: CGPoint, untrimmedSize: CGSize) {
        self._texture = texture
        self.rect = rect
        self.trimOffset = trimOffset
        self.untrimmedSize = untrimmedSize
        self.rotated = rotated
        super.init()
    }
    
    override var description: String {
        return "<CCSpriteFrame: Texture=\(textureFilename), Rect = (%.2f,%.2f,%.2f,%.2f)> rotated:\(rect.origin.x) offset=(%.2f,%.2f)"
    }
    
    func setTexture(_ texture: CCTexture) {
        if _texture != texture {
            self._texture = texture
        }
    }

    func hasProxy() -> Bool {
        return _proxy != nil
    }
    
    class func purgeCache() {
        // TODO not thread safe.
        CCSpriteFrameCache.shared().removeUnusedSpriteFrames()
    }
}
