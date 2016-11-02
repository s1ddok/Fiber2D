//
//  RenderTexture.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation
import Metal
import SwiftMath

/**
 *  Image format when saving render textures. Used by CCRenderTexture.
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
class RenderTexture: RenderableNode {
    /**
     *  Initializes a RenderTexture object with width and height in points 
     *
     *  @param w                  Width of render target.
     *  @param h                  Height of render target.
     *
     *  @return An initialized CCRenderTarget object.
     *  @see CCTexturePixelFormat
     */
    
    init(width w: Int, height h: Int) {
        super.init()
        self.contentScale = CCSetup.shared().assetScale
        self.contentSize = Size(width: w, height: h)
        self.projection = Matrix4x4f.ortho(left: 0.0, right: Float(w), bottom: 0.0, top: Float(h), near: -1024, far: 1024)
        let rtSprite: RenderTextureSprite = RenderTextureSprite(texture: /*CCTexture.none()*/nil, rect: Rect.zero, rotated: false)
        rtSprite.renderTexture = self
        self.sprite = rtSprite

    }
    deinit {
        destroy()
    }
    /**
     *  @name Begin and End Drawing
     */
    
    /**
     Starts rendering to the texture whitout clearing the texture first.
     @returns A CCRenderer instance used for drawing.
     */
    
    func begin() -> Renderer {
        /*var texture: CCTexture! = self.texture
        if texture == nil {
            self.create()
            texture = self.texture
        }*/
        let renderer: Renderer = Director.currentDirector!.rendererFromPool()
        // TODO: Renderer
        renderer.prepare(withProjection: _projection)
        self.previousRenderer = currentRenderer
        currentRenderer = renderer
        //CCRenderer.bindRenderer(renderer)
        return renderer
    }
    
    /**
     *  Starts rendering to the texture while clearing the texture first.
     *  This is more efficient then calling clear and begin separately.
     *
     *  @param r Red color.
     *  @param g Green color.
     *  @param b Blue color.
     *  @param a Alpha.
     *  @returns A CCRenderer instance used for drawing.
     */
    
    func beginWithClear(_ r: Float, g: Float, b: Float, a: Float, flags: MTLLoadAction = .clear) -> Renderer {
        let renderer: Renderer = self.begin()
        renderer.enqueueClear(color: Color(r, g, b, a))
        return renderer
    }
    
    /**
     *  Ends rendering and allows you to use the texture, ie save it or using it in a sprite.
     */
    
    func end() {
        let renderer = currentRenderer!
        let director: Director = Director.currentDirector!
        director.add {
            // Return the renderer to the pool when the frame completes.
            director.poolRenderer(renderer)
        }
        renderer.flush()
        currentRenderer = previousRenderer
        //CCRenderer.bindRenderer(previousRenderer)
    }
    /**
     *  @name Clearing the Render Texture
     */
    /**
     *  Clears the texture with a color
     *
     *  @param r Red color.
     *  @param g Green color.
     *  @param b Blue color.
     *  @param a Alpha.
     */
    
    func clear(_ r: Float, g: Float, b: Float, a: Float) {
        let _ = self.beginWithClear(r, g: g, b: b, a: a)
        self.end()
    }
    /** Clear color value. Valid only when autoDraw is YES.
     @see Color */
    var clearColor = Color.clear
    /** @name Render Texture Drawing Properties */
    /**
     When enabled, it will render its children into the texture automatically.
     */
    var autoDraw: Bool = true
    /**
     *  @name Accessing the Sprite and Texture
     */
    /** The CCSprite that is used for rendering.
     
     @note A subtle change introduced in v3.1.1 is that this sprite is rendered explicitly and is no longer a child of the render texture.
     @see CCSprite
     */
    var sprite: Sprite!
    // Reference to the previous render to be restored by end.
    var previousRenderer: Renderer?
    
    // Raw projection matrix used for rendering.
    // For metal will be flipped on the y-axis compared to the .projection property.
    var projection: Matrix4x4f {
        get {
            return Matrix4x4f.scale(sx: 1.0, sy: -1.0, sz: 1.0) * _projection
        }
        set {
            _projection = Matrix4x4f.scale(sx: 1.0, sy: -1.0, sz: 1.0) * newValue
        }
    }
    private var _projection  = Matrix4x4f.identity

    //var framebuffer: CCFrameBufferObject?
    
    
    func createTextureAndFboWithPixelSize(_ pixelSize: Size) {
        /*let paddedSize: Size = pixelSize
        /*if(![[CCDeviceInfo sharedDeviceInfo] supportsNPOT]){
         paddedSize.width = CCNextPOT(pixelSize.width);
         paddedSize.height = CCNextPOT(pixelSize.height);
        	}*/
        let image = Image(pixelSize: paddedSize, contentScale: contentScale, pixelData: nil)
        image.contentSize = pixelSize * (1.0 / contentScale)
        self.texture = CCTexture(image: image, options: nil, rendertexture: true)
        self.framebuffer = CCFrameBufferObjectMetal(texture: texture, depthStencilFormat: .bgra8Unorm)
        // XXX Thayer says: I think this is incorrect for any situations where the content
        // size type isn't (points, points). The call to setTextureRect below eventually arrives
        // at some code that assumes the supplied size is in points so, if the size is not in points,
        // things break.
        self.assignSpriteTexture()
        let size = self.contentSize
        let textureSize = Rect(origin: p2d.zero, size: size)
        sprite.setTextureRect(textureSize, forTexture: sprite.texture, rotated: false, untrimmedSize: textureSize.size)*/
    }
    
    func create() {
        let size: Size = self.contentSize
        let pixelSize: Size = Size(width: size.width * Float(contentScale), height: size.height * Float(contentScale))
        self.createTextureAndFboWithPixelSize(pixelSize)
    }
    func destroy() {
        //framebuffer = nil
        texture = nil
    }
    
    func assignSpriteTexture() {
        sprite.texture = texture
    }
    /** The render texture's (and its sprite's) texture.
     @see Texture */
    override var texture: Texture! {
        get {
            if (super.texture == nil) {
                create()
            }
            return super.texture
        }
        set {
            super.texture = newValue
        }
    }
    
    /** The render texture's content scale factor. */
    var contentScale: Float = CCSetup.shared().assetScale {
        didSet {
            if contentScale != oldValue {
                destroy()
            }
        }
    }
    
    override func visit(_ renderer: Renderer, parentTransform: Matrix4x4f) {
        // override visit.
        // Don't call visit on its children
        guard self.visible else {
            return
        }
        if autoDraw {
            let rtRenderer = self.begin()
            //assert(renderer == renderer, "CCRenderTexture error!")
            rtRenderer.enqueueClear(color: clearColor)
            //! make sure all children are drawn
            self.sortAllChildren()
            for child: Node in children {
                child.visit(rtRenderer, parentTransform: _projection)
            }
        
            self.end()
            let transform = parentTransform * self.nodeToParentMatrix
            self.draw(renderer, transform: transform)
        }
        else {
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
