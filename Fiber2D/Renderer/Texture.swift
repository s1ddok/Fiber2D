//
//  Texture.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 02.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath
import SwiftBGFX

internal typealias BGFXTexture = SwiftBGFX.Texture

public class Texture {
    internal var texture: BGFXTexture
    internal var contentSizeInPixels: Size = .zero
    
    /**
     Content scale of the texture.
     */
    internal(set) public var contentScale: Float = 1.0
    
    /**
     Content size of the texture.
     This may not be sizeInPixels/contentSize. A texture might be padded to a size that is a power of two on some Android hardware.
     */
    public var contentSize: Size {
        return contentSizeInPixels * (1.0 / contentScale)
    }
    
    /**
     Size of the texture in pixels.
     */
    public var sizeInPixels: Size {
        return Size(Float(texture.info.width), Float(texture.info.height))
    }
    
    /**
     A sprite frame that covers the whole texture.
     */
    public var spriteFrame: SpriteFrame {
        if _spriteFrame == nil {
            _spriteFrame = SpriteFrame(texture: self, rect: Rect(size: contentSize), rotated: false, trimOffset: .zero, untrimmedSize: contentSize)
        }
        
        return _spriteFrame!
    }
    private var _spriteFrame: SpriteFrame? = nil
    
    internal init(bgfxTexture: BGFXTexture) {
        self.texture = bgfxTexture
    }
    
    public static func load(from filename: String) -> Texture? {
        return TextureCache.shared.addImage(from: filename)
    }
}
