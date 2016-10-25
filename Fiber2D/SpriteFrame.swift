//
//  SpriteFrame.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

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
    
    private weak var _proxy: CCProxy?
    
    var lazyTexture: CCTexture {
        if _lazyTexture == nil && textureFilename != "" {
            _lazyTexture = CCTextureCache.shared().addImage(textureFilename)
            _texture = _lazyTexture
        }
        return texture
    }
    private var _lazyTexture: CCTexture?
    
    /** Rectangle of the frame within the texture, in points. */
    var rect: Rect
    /** If YES, the frame rectangle is rotated. */
    var rotated: Bool
    /** To save space in a spritesheet, the transparent edges of a frame may be trimmed. This is the original size in points of a frame before it was trimmed. */
    var untrimmedSize: Size
    /** To save space in a spritesheet, the transparent edges of a frame may be trimmed. This is offset of the sprite caused by trimming in points. */
    var trimOffset: Point
    
    static func frameWithImageNamed(_ imageName: String) -> SpriteFrame! {
        return CCSpriteFrameCache.shared().spriteFrame(byName: imageName)
    }
    convenience init(texture: CCTexture!, rect: CGRect, rotated: Bool, trimOffset: CGPoint, untrimmedSize: CGSize) {
        self.init(texture: texture, rect: Rect(CGRect: rect), rotated: rotated, trimOffset: Point(trimOffset), untrimmedSize: Size(CGSize: untrimmedSize))
    }
    init(texture: CCTexture!, rect: Rect, rotated: Bool, trimOffset: Point, untrimmedSize: Size) {
        self._texture = texture
        self.rect = rect
        self.trimOffset = trimOffset
        self.untrimmedSize = untrimmedSize
        self.rotated = rotated
        super.init()
    }
    
    override var description: String {
        return "<CCSpriteFrame: Texture=\(textureFilename), Rect = \(rect.description)> rotated:\(rotated) offset=\(trimOffset.description))"
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
