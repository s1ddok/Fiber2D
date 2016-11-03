//
//  SpriteFrame.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

/**
 A SpriteFrame contains the texture and rectangle of the texture to be used by a Sprite.
 You can easily modify the sprite frame of a Sprite using the following handy method:
 let frame = SpriteFrame.with(imageName: "jump.png")
 sprite.spriteFrame = frame
 */
public final class SpriteFrame {
    /// @name Creating a Sprite Frame
    
    /**
     *  Create and return a sprite frame object from the specified image name. On first attempt it will check the internal texture/frame cache
     *  and if not available will then try and create the frame from an image file of the same name.
     *
     *  @param imageName Image name.
     *
     *  @return The SpriteFrame Object.
     */
    public static func with(imageName: String) -> SpriteFrame! {
        return SpriteFrameCache.shared.spriteFrame(by: imageName)
    }
    
    /**
     *  Initializes and returns a sprite frame object from the specified texture, texture rectangle, rotation status, offset and originalSize values.
     *
     *  @param texture Texture to use.
     *  @param rect Texture rectangle (in points) to use.
     *  @param rotated Is rectangle rotated?
     *  @param trimOffset Offset (in points) to use.
     *  @param untrimmedSize Original size (in points) before being trimmed.
     *
     *  @return An initialized SpriteFrame Object.
     *  @see Texture
     */
    public init(texture: Texture!, rect: Rect, rotated: Bool, trimOffset: Point, untrimmedSize: Size) {
        self._texture = texture
        self.rect = rect
        self.trimOffset = trimOffset
        self.untrimmedSize = untrimmedSize
        self.rotated = rotated
    }
    
    /** Texture used by the frame.
     @see Texture */
    public var texture: Texture {
        return _texture ?? lazyTexture
    }
    internal var _texture: Texture?
    
    /** Texture image file name used to create the texture. Set by the sprite frame cache */
    internal(set) public var textureFilename: String = "" {
        didSet {
            // Make sure any previously loaded texture is cleared.
            self._texture = nil
            self._lazyTexture = nil
        }
    }

    internal var lazyTexture: Texture {
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
    
    public var description: String {
        return "<SpriteFrame: Texture=\(textureFilename), Rect = \(rect.description)> rotated:\(rotated) offset=\(trimOffset.description))"
    }
    
    /**
     Purge all unused spriteframes from the cache.
     */
    public static func purgeCache() {
        SpriteFrameCache.shared.removeUnusedSpriteFrames()
    }
}
