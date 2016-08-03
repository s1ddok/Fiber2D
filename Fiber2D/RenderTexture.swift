//
//  RenderTexture.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation

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
        self.contentSize = CGSize(width: CGFloat(w), height: CGFloat(h))
        self.projection = GLKMatrix4MakeOrtho(0.0, Float(w), 0.0, Float(h), -1024.0, 1024.0)
        let rtSprite: RenderTextureSprite = RenderTextureSprite(texture: CCTexture.none(), rect: CGRect.zero, rotated: false)
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
    
    func begin() -> CCRenderer {
        var texture: CCTexture! = self.texture
        if texture == nil {
            self.create()
            texture = self.texture
        }
        let renderer: CCRenderer = Director.currentDirector()!.rendererFromPool()
        renderer.prepare(withProjection: &projection, framebuffer: framebuffer)
        self.previousRenderer = CCRenderer.current()
        CCRenderer.bindRenderer(renderer)
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
    
    func beginWithClear(_ r: Float, g: Float, b: Float, a: Float, flags: MTLLoadAction = .clear) -> CCRenderer {
        let renderer: CCRenderer = self.begin()
        renderer.enqueueClear(flags, color: GLKVector4Make(r, g, b, a), globalSortOrder: NSInteger.min)
        return renderer
    }
    
    /**
     *  Ends rendering and allows you to use the texture, ie save it or using it in a sprite.
     */
    
    func end() {
        let renderer: CCRenderer = CCRenderer.current()
        let director: Director = Director.currentDirector()!
        director.addFrameCompletionHandler {
            // Return the renderer to the pool when the frame completes.
            director.poolRenderer(renderer)
        }
        renderer.flush()
        CCRenderer.bindRenderer(previousRenderer)
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
        self.beginWithClear(r, g: g, b: b, a: a)
        self.end()
    }
    /** Clear color value. Valid only when autoDraw is YES.
     @see CCColor */
    var clearColor = CCColor.clear()
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
    var previousRenderer: CCRenderer!
    
    private func FlipY(_ matrix: GLKMatrix4) -> GLKMatrix4 {
        return GLKMatrix4Multiply(GLKMatrix4MakeScale(1.0, -1.0, 1.0), matrix);
    }
    // Raw projection matrix used for rendering.
    // For metal will be flipped on the y-axis compared to the .projection property.
    var projection: GLKMatrix4 /*{
        get {
            return FlipY(_projection)
        }
        set {
            _projection = FlipY(newValue)
        }
    }
    private var _projection */ = GLKMatrix4Identity

    var framebuffer: CCFrameBufferObject?
    
    
    func createTextureAndFboWithPixelSize(_ pixelSize: CGSize) {
        let paddedSize: CGSize = pixelSize
        /*if(![[CCDeviceInfo sharedDeviceInfo] supportsNPOT]){
         paddedSize.width = CCNextPOT(pixelSize.width);
         paddedSize.height = CCNextPOT(pixelSize.height);
        	}*/
        let image: CCImage = CCImage(pixelSize: paddedSize, contentScale: CGFloat(contentScale), pixelData: nil)
        image.contentSize = CC_SIZE_SCALE(pixelSize, 1.0 / CGFloat(contentScale))
        self.texture = CCTexture(image: image, options: nil, rendertexture: true)
        self.framebuffer = CCFrameBufferObjectMetal(texture: texture, depthStencilFormat: .bgra8Unorm)
        // XXX Thayer says: I think this is incorrect for any situations where the content
        // size type isn't (points, points). The call to setTextureRect below eventually arrives
        // at some code that assumes the supplied size is in points so, if the size is not in points,
        // things break.
        self.assignSpriteTexture()
        let size: CGSize = self.contentSize
        let textureSize: CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        sprite.setTextureRect(textureSize, forTexture: sprite.texture, rotated: false, untrimmedSize: textureSize.size)
    }
    
    func create() {
        let size: CGSize = self.contentSize
        let pixelSize: CGSize = CGSize(width: size.width * CGFloat(contentScale), height: size.height * CGFloat(contentScale))
        self.createTextureAndFboWithPixelSize(pixelSize)
    }
    func destroy() {
        framebuffer = nil
        texture = nil
    }
    
    func assignSpriteTexture() {
        sprite.texture = texture
    }
    /** The render texture's (and its sprite's) texture.
     @see CCTexture */
    override var texture: CCTexture! {
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
    
    override func visit(_ renderer: CCRenderer, parentTransform: GLKMatrix4) {
        // override visit.
        // Don't call visit on its children
        guard self.visible else {
            return
        }
        if autoDraw {
            let rtRenderer: CCRenderer = self.begin()
            assert(renderer == renderer, "CCRenderTexture error!")
            rtRenderer.enqueueClear(.clear, color: (clearColor?.glkVector4)!, globalSortOrder: NSInteger.min)
            //! make sure all children are drawn
            self.sortAllChildren()
            for child: Node in children {
                child.visit(rtRenderer, parentTransform: projection)
            }
        
            self.end()
            let transform: GLKMatrix4 = GLKMatrix4Multiply(parentTransform, self.nodeToParentMatrix())
            self.draw(renderer, transform: transform)
        }
        else {
            // Render normally, v3.0 and earlier skipped this.
            super.visit(renderer, parentTransform: parentTransform)
        }
        
    }
    
    override func draw(_ renderer: CCRenderer, transform: GLKMatrix4) {
        assert(sprite.zOrder == 0, "Changing the sprite's zOrder is not supported.")
        // Force the sprite to render itself
        sprite.visit(renderer, parentTransform: transform)
    }
}
