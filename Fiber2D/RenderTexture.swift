//
//  RenderTexture.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation
import Metal
import SwiftMath
import SwiftBGFX

/**
 *  Image format when saving render textures. Used by RenderTexture.
 */
enum RenderTextureImageFormat : Int {
    /** Image will be saved as JPEG */
    case jpeg = 0
    /** Image will be saved as PNG */
    case png = 1
}

/**
 RenderTexture is a generic render target. To render things into it, simply create a render texture node, call begin on it,
 call visit on any Fiber2D scene or branch of the node tree to render it onto the render texture, then call end.
 
 For convenience, render texture has a sprite property with the results, so you can just add the render texture
 to your scene and treat it like any other Node.
 
 There are also functions for saving the render texture to disk in PNG or JPG format.
 */
public final class RenderTexture: RenderableNode {
    
    /**
     *  Initializes a RenderTexture object with width and height in points 
     *
     *  @param w Width of render target.
     *  @param h Height of render target.
     *
     *  @return An initialized RenderTexture object.
     */
    public init(width w: UInt, height h: UInt) {
        super.init()
        self.contentScale = Setup.shared.assetScale
        self.contentSize = Size(width: Float(w), height: Float(h))
        self.projection = Matrix4x4f.orthoProjection(for: self)
        let rtSprite: RenderTextureSprite = RenderTextureSprite(texture: nil, rect: Rect.zero, rotated: false)
        rtSprite.renderTexture = self
        self.sprite = rtSprite

    }

    /** Clear color value. Valid only when autoDraw is YES.
     @see Color */
    public var clearColor = Color.clear
    
    /** @name Render Texture Drawing Properties */
    /**
     When enabled, it will render its children into the texture automatically.
     */
    public var autoDraw: Bool = true
    
    /**
     *  @name Accessing the Sprite and Texture
     */
    /** The Sprite that is used for rendering.
     
     @see Sprite
     */
    public var sprite: Sprite!
    
    // Raw projection matrix used for rendering.
    // For metal will be flipped on the y-axis compared to the ._projection property.
    public var projection: Matrix4x4f {
        get {
            // TODO: Do this only if BGFX uses Metal backend?
            return Matrix4x4f.scale(sx: 1.0, sy: -1.0, sz: 1.0) * _projection
        }
        set {
            _projection = Matrix4x4f.scale(sx: 1.0, sy: -1.0, sz: 1.0) * newValue
        }
    }
    internal var _projection = Matrix4x4f.identity
    
    internal func createTextureAndFBO(with pixelSize: Size) {
        // TODO: Pad to POT if hardware doesnt support NPOT
        let paddedSize: Size = pixelSize
        
        self.texture = Texture.makeRenderTexture(of: paddedSize)
        self.framebuffer = FrameBuffer(textures: [texture.texture], destroyTextures: false)
        
        // XXX. I think this is incorrect for any situations where the content
        // size type isn't (points, points). The call to setTextureRect below eventually arrives
        // at some code that assumes the supplied size is in points so, if the size is not in points,
        // things break.
        self.assignSpriteTexture()
        let size = self.contentSize
        let textureSize = Rect(size: size)
        sprite.setTextureRect(textureSize, forTexture: sprite.texture, rotated: false, untrimmedSize: textureSize.size)
    }
    
    internal func destroy() {
        framebuffer = nil
        texture = nil
    }
    
    internal func assignSpriteTexture() {
        sprite.texture = texture
    }
    
    /** The render texture's (and its sprite's) texture.
     @see Texture */
    override public var texture: Texture! {
        get {
            if (super.texture == nil) {
                createTextureAndFBO(with: pixelSize)
            }
            return super.texture
        }
        set {
            super.texture = newValue
        }
    }
    
    /** The render texture's content scale factor. */
    public var contentScale: Float = Setup.shared.assetScale {
        didSet {
            if contentScale != oldValue {
                destroy()
            }
        }
    }
    
    /** The render texture's size in pixels. */
    public var pixelSize: Size {
        return contentSize * contentScale
    }
    
    internal var framebuffer: FrameBuffer?
    
    override func visit(_ renderer: Renderer, parentTransform: Matrix4x4f) {
        // override visit.
        // Don't call visit on its children
        guard self.visible else {
            return
        }
        
        if autoDraw {
            assignSpriteTexture()
            renderer.beginRenderTexture(self)
            //! make sure all children are drawn
            self.sortAllChildren()
            for child in children {
                child.visit(renderer, parentTransform: _projection)
            }
        
            renderer.endRenderTexture()
            
            let transform = parentTransform * self.nodeToParentMatrix
            self.draw(renderer, transform: transform)
        } else {
            // Render normally, v3.0 and earlier skipped this.
            super.visit(renderer, parentTransform: parentTransform)
        }
    }
    
    override func draw(_ renderer: Renderer, transform: Matrix4x4f) {
        assert(sprite.zOrder == 0, "Changing the sprite's zOrder is not supported.")
        // Force the sprite to render itself
        sprite.visit(renderer, parentTransform: transform)
    }
}
