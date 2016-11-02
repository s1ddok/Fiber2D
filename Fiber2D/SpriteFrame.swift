//
//  SpriteFrame.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

public class SpriteFrame {
    var texture: Texture {
        return _texture ?? lazyTexture
    }
    var _texture: Texture?
    var textureFilename: String = "" {
        didSet {
            // Make sure any previously loaded texture is cleared.
            self._texture = nil
            self._lazyTexture = nil
        }
    }

    var lazyTexture: Texture {
        if _lazyTexture == nil && textureFilename != "" {
            _lazyTexture = TextureCache.shared.addImage(from: textureFilename)
            _texture = _lazyTexture
        }
        return texture
    }
    private var _lazyTexture: Texture?
    
    /** Rectangle of the frame within the texture, in points. */
    public var rect: Rect
    
    /** If YES, the frame rectangle is rotated. */
    public var rotated: Bool
    
    /** To save space in a spritesheet, the transparent edges of a frame may be trimmed. This is the original size in points of a frame before it was trimmed. */
    public var untrimmedSize: Size
    
    /** To save space in a spritesheet, the transparent edges of a frame may be trimmed. This is offset of the sprite caused by trimming in points. */
    public var trimOffset: Point
    
    public static func with(imageName: String) -> SpriteFrame! {
        return SpriteFrameCache.shared.spriteFrame(by: imageName)
    }
    
    public convenience init(texture: Texture!, rect: CGRect, rotated: Bool, trimOffset: CGPoint, untrimmedSize: CGSize) {
        self.init(texture: texture, rect: Rect(CGRect: rect), rotated: rotated, trimOffset: Point(trimOffset), untrimmedSize: Size(CGSize: untrimmedSize))
    }
    
    public init(texture: Texture!, rect: Rect, rotated: Bool, trimOffset: Point, untrimmedSize: Size) {
        self._texture = texture
        self.rect = rect
        self.trimOffset = trimOffset
        self.untrimmedSize = untrimmedSize
        self.rotated = rotated
    }
    
    public var description: String {
        return "<SpriteFrame: Texture=\(textureFilename), Rect = \(rect.description)> rotated:\(rotated) offset=\(trimOffset.description))"
    }
    
    public static func purgeCache() {
        // TODO not thread safe.
        SpriteFrameCache.shared.removeUnusedSpriteFrames()
    }
}
