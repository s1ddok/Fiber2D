//
//  Sprite.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

/// The four CCVertexes of a sprite.
/// Bottom left, bottom right, top right, top left.
struct SpriteVertexes {
    var bl, br, tr, tl: CCVertex
    
    init() {
        bl = CCVertex()
        br = bl
        tr = bl
        tl = bl
    }
}

/// A set of four texture coordinates corresponding to the four
/// vertices of a sprite.
struct SpriteTexCoordSet {
    var bl, br, tr, tl: GLKVector2
    
    init() {
        bl = GLKVector2Make(0.0, 0.0)
        br = bl
        tr = bl
        tl = bl
    }
}

// The output below is limited by 4 KB.
// Upgrade your plan to remove this limitation.

/**
 Sprite draws a CCTexture on the screen. Sprite can be created with an image, with a sub-rectangle of an (atlas) image.
 
 The default anchorPoint in Sprite is (0.5, 0.5).
 */
class Sprite: RenderableNode {
    // Vertex coords, texture coords and color info.
    var verts = SpriteVertexes()
    // Center of extents (half width/height) of the sprite for culling purposes.
    var vertexCenter = GLKVector2()
    var vertexExtents = GLKVector2()
    private // Offset Position, used by sprite sheet editors.
    var unflippedOffsetPositionFromCenter = CGPoint.zero
    
    class func textureCoordsForTexture(_ texture: CCTexture!, withRect rect: CGRect, rotated: Bool, xFlipped flipX: Bool, yFlipped flipY: Bool) -> SpriteTexCoordSet {
        var result = SpriteTexCoordSet()
        guard let texture = texture else {
            return result
        }
        // Need to convert the texel coords for the texel stretch hack. (Bah)
        let scale: CGFloat = texture.contentScale
        let rect = CC_RECT_SCALE(rect, scale)
        let sizeInPixels: CGSize = texture.sizeInPixels
        let atlasWidth = sizeInPixels.width
        let atlasHeight = sizeInPixels.height
        
        var left = Float(rect.origin.x / atlasWidth)
        var right = Float((rect.origin.x + rect.size.height) / atlasWidth)
        var bottom = Float(rect.origin.y / atlasHeight)
        var top = Float((rect.origin.y + rect.size.width) / atlasHeight)
        
        if rotated {
            if flipX {
                swap(&top, &bottom)
            }
            if flipY {
                swap(&left, &right)
            }
            result.bl = GLKVector2Make(left, top)
            result.br = GLKVector2Make(left, bottom)
            result.tr = GLKVector2Make(right, bottom)
            result.tl = GLKVector2Make(right, top)
        }
        else {
            if flipX {
                swap(&left, &right)
            }
            if flipY {
                swap(&top, &bottom)
            }
            result.bl = GLKVector2Make(left, bottom)
            result.br = GLKVector2Make(right, bottom)
            result.tr = GLKVector2Make(right, top)
            result.tl = GLKVector2Make(left, top)
        }
        return result
    }
    /**
     *  Initializes a sprite with the name of an image. The name can be either a name in a sprite sheet or the name of a file.
     *
     *  @param imageName name of the image to load.
     *
     *  @return A newly initialized Sprite object.
     */
    
    convenience init(imageNamed imageName: String) {
        let spriteFrame = SpriteFrame.frameWithImageNamed(imageName)
        self.init(spriteFrame: spriteFrame!)
    }
    /**
     *  Initializes an sprite with an existing SpriteFrame.
     *
     *  @param spriteFrame Sprite frame to use.
     *
     *  @return A newly initialized Sprite object.
     *  @see SpriteFrame
     */
    
    convenience init(spriteFrame: SpriteFrame) {
        self.init(texture: spriteFrame.texture, rect: spriteFrame.rect)
        self.spriteFrame = spriteFrame
    }
    
    /**
     *  Initializes a sprite with an existing CCTexture and a rect in points, optionally rotated.
     *  The offset will be (0,0).
     *  @note This is the designated initializer.
     *
     *  @param texture The texture to use.
     *  @param rect    The rect to use.
     *  @param rotated YES if texture is rotated.
     *
     *  @return A newly initialized Sprite object.
     *  @see CCTexture
     */
    
    init(texture: CCTexture? = nil, rect: CGRect = CGRect.zero, rotated: Bool = false) {
        super.init()
        self.blendMode = CCBlendMode.premultipliedAlpha()
        self.shader = CCShader.positionTextureColor()
        // default transform anchor: center
        self.anchorPoint = ccp(0.5, 0.5)
        self.updateColor()
        self.texture = texture
        self.setTextureRect(rect, forTexture: self.texture, rotated: rotated, untrimmedSize: rect.size)

    }
    
    /// -----------------------------------------------------------------------
    /// @name Flipping a Sprite
    /// -----------------------------------------------------------------------
    /** Whether or not the sprite is flipped horizontally.
     @note Flipping does not flip any of the sprite's child sprites nor does it alter the anchorPoint.
     If that is what you want, you should try inversing the Node scaleX property: `sprite.scaleX *= -1.0;`.
     */
    var flipX: Bool = false {
        didSet {
            if flipX != oldValue {
                self.setTextureRect(textureRect, forTexture: self.texture, rotated: textureRectRotated, untrimmedSize: self.contentSize)
            }
        }
    }
    /** Whether or not the sprite is flipped vertically.
     @note Flipping does not flip any of the sprite's child sprites nor does it alter the anchorPoint.
     If that is what you want, you should try inversing the Node scaleY property: `sprite.scaleY *= -1.0;`.
     */
    var flipY: Bool = false {
        didSet {
            if flipY != oldValue {
                self.setTextureRect(textureRect, forTexture: self.texture, rotated: textureRectRotated, untrimmedSize: self.contentSize)
            }
        }
    }
    /// -----------------------------------------------------------------------
    /// @name Accessing the Sprite Frames
    /// -----------------------------------------------------------------------
    /** The currently displayed spriteFrame.
     @see SpriteFrame */
    var spriteFrame: SpriteFrame! {
        didSet {
            self.unflippedOffsetPositionFromCenter = spriteFrame.trimOffset
            self.texture = spriteFrame.texture
            self.setTextureRect(spriteFrame.rect, forTexture: self.texture, rotated: spriteFrame.rotated, untrimmedSize: spriteFrame.untrimmedSize)
        }
    }
    /** The secondary spriteFrame used by effect shaders. (Ex: Custom shaders or normal mapping)
     @see SpriteFrame */
    var spriteFrame2: SpriteFrame? {
        didSet {
            guard let spriteFrame2 = spriteFrame2 else {
                return
            }
            self.secondaryTexture = spriteFrame2.texture
            // Set the second texture coordinate set from the normal map's sprite frame.
            let texCoords: SpriteTexCoordSet = Sprite.textureCoordsForTexture(spriteFrame2.texture, withRect: spriteFrame2.rect, rotated: spriteFrame2.rotated, xFlipped: flipX, yFlipped: flipY)
            self.verts.bl.texCoord2 = texCoords.bl
            self.verts.br.texCoord2 = texCoords.br
            self.verts.tr.texCoord2 = texCoords.tr
            self.verts.tl.texCoord2 = texCoords.tl
        }
    }
    /// -----------------------------------------------------------------------
    /// @name Working with the Sprite's Texture
    /// -----------------------------------------------------------------------
    /*var vertexes: UnsafeMutablePointer<SpriteVertexes> {
        return &verts
    }*/
    
    /** The offset position in points of the sprite in points. Calculated automatically by sprite sheet editors. */
    private(set) var offsetPosition = CGPoint.zero
    
    /** Returns the texture rect of the Sprite in points. */
    private(set) var textureRect = CGRect.zero
    
    /** Returns whether or not the texture rectangle is rotated. Sprite sheet editors may rotate sprite frames in a texture to fit more sprites in the same atlas. */
    private(set) var textureRectRotated: Bool = false
    
    /**
     *  Set the texture rect, rectRotated and untrimmed size of the Sprite in points.
     *  It will update the texture coordinates and the vertex rectangle.
     *
     *  @param rect    Rect to use.
     *  @param rotated YES if texture is rotated.
     *  @param size    Untrimmed size.
     */
    
    func setTextureRect(_ rect: CGRect, forTexture texture: CCTexture, rotated: Bool, untrimmedSize: CGSize) {
        self.textureRectRotated = rotated
        self.contentSizeType = CCSizeTypePoints
        self.contentSize = untrimmedSize
        self.textureRect = rect
        let texCoords: SpriteTexCoordSet = Sprite.textureCoordsForTexture(texture, withRect: rect, rotated: rotated, xFlipped: flipX, yFlipped: flipY)
        self.verts.bl.texCoord1 = texCoords.bl
        self.verts.br.texCoord1 = texCoords.br
        self.verts.tr.texCoord1 = texCoords.tr
        self.verts.tl.texCoord1 = texCoords.tl
        var relativeOffset = unflippedOffsetPositionFromCenter
        // issue #732
        if flipX {
            relativeOffset.x = -relativeOffset.x
        }
        if flipY {
            relativeOffset.y = -relativeOffset.y
        }
        let size: CGSize = self.contentSize
        self.offsetPosition.x = relativeOffset.x + (size.width - textureRect.size.width) / 2
        self.offsetPosition.y = relativeOffset.y + (size.height - textureRect.size.height) / 2
        // Atlas: Vertex
        let x1 = Float(offsetPosition.x)
        let y1 = Float(offsetPosition.y)
        let x2 = x1 + Float(textureRect.size.width)
        let y2 = y1 + Float(textureRect.size.height)
        self.verts.bl.position = GLKVector4Make(x1, y1, 0.0, 1.0)
        self.verts.br.position = GLKVector4Make(x2, y1, 0.0, 1.0)
        self.verts.tr.position = GLKVector4Make(x2, y2, 0.0, 1.0)
        self.verts.tl.position = GLKVector4Make(x1, y2, 0.0, 1.0)
        // Set the center/extents for culling purposes.
        self.vertexCenter = GLKVector2Make((x1 + x2) * 0.5, (y1 + y2) * 0.5)
        self.vertexExtents = GLKVector2Make((x2 - x1) * 0.5, (y2 - y1) * 0.5)
    }
    /** Returns the matrix that transforms the sprite's (local) space coordinates into the sprite's texture space coordinates.
     */
    
    func nodeToTextureTransform() -> GLKMatrix4 {
        let sx = Float((verts.br.texCoord1.s - verts.bl.texCoord1.s) / (verts.br.position.x - verts.bl.position.x))
        let sy = Float((verts.tl.texCoord1.t - verts.bl.texCoord1.t) / (verts.tl.position.y - verts.bl.position.y))
        let tx = Float(verts.bl.texCoord1.s - verts.bl.position.x * sx)
        let ty = Float(verts.bl.texCoord1.t - verts.bl.position.y * sy)
        return GLKMatrix4Make(sx, 0.0, 0.0, 0.0,
                              0.0, sy, 0.0, 0.0,
                              0.0, 0.0, 1.0, 0.0,
                              tx, ty, 0.0, 1.0)

    }
    
    //
    // RGBA protocol
    //
    
    // MARK: RGBA protocol
    
    
    func updateColor() {
        let color4: GLKVector4 = displayedColor.premultiplyingAlpha().glkVector4
        self.verts.bl.color = color4
        self.verts.br.color = color4
        self.verts.tr.color = color4
        self.verts.tl.color = color4
    }
    
    override var color: Color {
        didSet {
            self.updateColor()
        }
    }
    
    override var colorRGBA: Color {
        didSet {
            self.updateColor()
        }
    }
    
    override func updateDisplayedColor(_ parentColor: GLKVector4) {
        super.updateDisplayedColor(parentColor)
        self.updateColor()
    }
    
    override var opacity: Float {
        didSet {
            self.updateColor()
        }
    }
    
    override func updateDisplayedOpacity(_ parentOpacity: Float) {
        super.updateDisplayedOpacity(parentOpacity)
        self.updateColor()
    }
    
    
    override func draw(_ renderer: CCRenderer, transform: GLKMatrix4) {
        var t = transform
        guard CCRenderCheckVisibility(&t, vertexCenter, vertexExtents) else {
            return
        }
        
        let buffer = renderer.enqueueTriangles(2, andVertexes: 4, with: self.renderState, globalSortOrder: 0)
        CCRenderBufferSetVertex(buffer, 0, CCVertexApplyTransform(self.verts.bl, &t))
        CCRenderBufferSetVertex(buffer, 1, CCVertexApplyTransform(self.verts.br, &t))
        CCRenderBufferSetVertex(buffer, 2, CCVertexApplyTransform(self.verts.tr, &t))
        CCRenderBufferSetVertex(buffer, 3, CCVertexApplyTransform(self.verts.tl, &t))
        CCRenderBufferSetTriangle(buffer, 0, 0, 1, 2)
        CCRenderBufferSetTriangle(buffer, 1, 0, 2, 3)
        
    }
    
}
