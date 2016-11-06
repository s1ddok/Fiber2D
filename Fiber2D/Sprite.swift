//
//  Sprite.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath
import SwiftBGFX

/// The four CCVertexes of a sprite.
/// Bottom left, bottom right, top right, top left.
public struct SpriteVertexes {
    var bl, br, tr, tl: RendererVertex
    
    init() {
        bl = RendererVertex()
        br = bl
        tr = bl
        tl = bl
    }
}

/// A set of four texture coordinates corresponding to the four
/// vertices of a sprite.
public struct SpriteTexCoordSet {
    var bl, br, tr, tl: Vector2f
    
    init() {
        bl = vec2(0.0, 0.0)
        br = bl
        tr = bl
        tl = bl
    }
}

/**
 Sprite draws a Texture on the screen. Sprite can be created with an image, with a sub-rectangle of an (atlas) image.
 
 The default anchorPoint in Sprite is (0.5, 0.5).
 */
open class Sprite: RenderableNode {
    /**
     *  Initializes a sprite with the name of an image. The name can be either a name in a sprite sheet or the name of a file.
     *
     *  @param imageName name of the image to load.
     *
     *  @return A newly initialized Sprite object.
     */
    convenience init(imageNamed imageName: String) {
        let spriteFrame = SpriteFrame.with(imageName: imageName)
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
     *  Initializes a sprite with an existing Texture and a rect in points, optionally rotated.
     *  The offset will be (0,0).
     *  @note This is the designated initializer.
     *
     *  @param texture The texture to use.
     *  @param rect    The rect to use.
     *  @param rotated YES if texture is rotated.
     *
     *  @return A newly initialized Sprite object.
     *  @see Texture
     */
    init(texture: Texture? = nil, rect: Rect = Rect.zero, rotated: Bool = false) {
        super.init()
        self.blendMode = .premultipliedAlphaMode
        self.shader = .posTexture
        // default transform anchor: center
        self.anchorPoint = p2d(0.5, 0.5)
        self.updateColor()
        self.texture = texture
        
        if texture != nil {
            self.setTextureRect(rect, forTexture: self.texture, rotated: rotated, untrimmedSize: rect.size)
        }
    }
    
    /// @name Flipping a Sprite
    
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
    
    /// @name Accessing the Sprite Frames
    
    /** The currently displayed spriteFrame.
     @see SpriteFrame */
    public var spriteFrame: SpriteFrame! {
        didSet {
            self.unflippedOffsetPositionFromCenter = spriteFrame.trimOffset
            self.texture = spriteFrame.texture
            self.setTextureRect(spriteFrame.rect, forTexture: self.texture, rotated: spriteFrame.rotated, untrimmedSize: spriteFrame.untrimmedSize)
        }
    }
    
    /** The secondary spriteFrame used by effect shaders. (Ex: Custom shaders or normal mapping)
     @see SpriteFrame */
    public var spriteFrame2: SpriteFrame? {
        didSet {
            guard let spriteFrame2 = spriteFrame2 else {
                return
            }
            //self.secondaryTexture = spriteFrame2.texture
            // Set the second texture coordinate set from the normal map's sprite frame.
            let texCoords: SpriteTexCoordSet = Sprite.textureCoords(for: spriteFrame2.texture, withRect: spriteFrame2.rect, rotated: spriteFrame2.rotated, xFlipped: flipX, yFlipped: flipY)
            self.verts.bl.texCoord2 = texCoords.bl
            self.verts.br.texCoord2 = texCoords.br
            self.verts.tr.texCoord2 = texCoords.tr
            self.verts.tl.texCoord2 = texCoords.tl
        }
    }
    
    /// @name Working with the Sprite's Texture
    
    /** The offset position in points of the sprite in points. Calculated automatically by sprite sheet editors. */
    private(set) public var offsetPosition = Point.zero
    
    /** Returns the texture rect of the Sprite in points. */
    private(set) public var textureRect = Rect.zero
    
    /** Returns whether or not the texture rectangle is rotated. Sprite sheet editors may rotate sprite frames in a texture to fit more sprites in the same atlas. */
    private(set) public var textureRectRotated: Bool = false
    
    /**
     *  Set the texture rect, rectRotated and untrimmed size of the Sprite in points.
     *  It will update the texture coordinates and the vertex rectangle.
     *
     *  @param rect    Rect to use.
     *  @param rotated YES if texture is rotated.
     *  @param size    Untrimmed size.
     */
    public func setTextureRect(_ rect: Rect, forTexture texture: Texture, rotated: Bool, untrimmedSize: Size) {
        self.textureRectRotated = rotated
        self.contentSizeType = .points
        self.contentSize = untrimmedSize
        self.textureRect = rect
        let texCoords: SpriteTexCoordSet = Sprite.textureCoords(for: texture, withRect: rect, rotated: rotated, xFlipped: flipX, yFlipped: flipY)
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
        let size = self.contentSize
        self.offsetPosition.x = relativeOffset.x + (size.width - textureRect.width) / 2
        self.offsetPosition.y = relativeOffset.y + (size.height - textureRect.height) / 2
        // Atlas: Vertex
        let x1 = offsetPosition.x
        let y1 = offsetPosition.y
        let x2 = x1 + textureRect.size.width
        let y2 = y1 + textureRect.size.height
        self.verts.bl.position = vec4(x1, y1, 0.0, 1.0)
        self.verts.br.position = vec4(x2, y1, 0.0, 1.0)
        self.verts.tr.position = vec4(x2, y2, 0.0, 1.0)
        self.verts.tl.position = vec4(x1, y2, 0.0, 1.0)
        // Set the center/extents for culling purposes.
        self.vertexCenter = vec2((x1 + x2) * 0.5, (y1 + y2) * 0.5)
        self.vertexExtents = vec2((x2 - x1) * 0.5, (y2 - y1) * 0.5)
    }
    
    /** Returns the matrix that transforms the sprite's (local) space coordinates into the sprite's texture space coordinates.
     */
    public var nodeToTextureTransform: Matrix4x4f {
        let sx = (verts.br.texCoord1.s - verts.bl.texCoord1.s) / (verts.br.position.x - verts.bl.position.x)
        let sy = (verts.tl.texCoord1.t - verts.bl.texCoord1.t) / (verts.tl.position.y - verts.bl.position.y)
        let tx = verts.bl.texCoord1.s - verts.bl.position.x * sx
        let ty = verts.bl.texCoord1.t - verts.bl.position.y * sy
        return Matrix4x4f(vec4(sx, 0.0, 0.0, 0.0),
                          vec4(0.0, sy, 0.0, 0.0),
                          vec4(0.0, 0.0, 1.0, 0.0),
                          vec4(tx, ty, 0.0, 1.0))

    }
    
    //
    // MARK: RGBA protocol
    //
    func updateColor() {
        let color4 = displayedColor.premultiplyingAlpha
        self.verts.bl.color = color4
        self.verts.br.color = color4
        self.verts.tr.color = color4
        self.verts.tl.color = color4
    }
    
    override public var color: Color {
        didSet {
            self.updateColor()
        }
    }
    
    override public var colorRGBA: Color {
        didSet {
            self.updateColor()
        }
    }
    
    override func updateDisplayedColor(_ parentColor: Color) {
        super.updateDisplayedColor(parentColor)
        self.updateColor()
    }
    
    override public var opacity: Float {
        didSet {
            self.updateColor()
        }
    }
    
    override func updateDisplayedOpacity(_ parentOpacity: Float) {
        super.updateDisplayedOpacity(parentOpacity)
        self.updateColor()
    }
    
    // Vertex coords, texture coords and color info.
    public var verts = SpriteVertexes()
    
    override func draw(_ renderer: Renderer, transform: Matrix4x4f) {

        let vertices = [verts.bl.transformed(transform),
                        verts.br.transformed(transform),
                        verts.tr.transformed(transform),
                        verts.tl.transformed(transform)]
        
        let vb = TransientVertexBuffer(count: 4, layout: RendererVertex.layout)
        memcpy(vb.data, vertices, 4 * MemoryLayout<RendererVertex>.size)
        bgfx.setVertexBuffer(vb)
        
        let ib = TransientIndexBuffer(count: 6)
        let indices: [UInt16] = [0, 1, 2, 0, 2, 3]
        memcpy(ib.data, indices, 6 * MemoryLayout<UInt16>.size)
        bgfx.setIndexBuffer(ib)

        bgfx.setTexture(0, sampler: uniform, texture: texture.texture)
        bgfx.setRenderState(renderState, colorRgba: 0x00)
        renderer.submit(shader: shader)
    }
    
    // MARK: Internal stuff

    // Center of extents (half width/height) of the sprite for culling purposes.
    internal var vertexCenter = vec2.zero
    internal var vertexExtents = vec2.zero
    // Offset Position, used by sprite sheet editors.
    private var unflippedOffsetPositionFromCenter = Point.zero
    
    // FIXME: Sits here until bgfx implements bgfx:getUniformInfo
    internal let uniform = Uniform(name: "u_mainTexture", type: .int1)
    
    internal static func textureCoords(for texture: Texture!, withRect rect: Rect, rotated: Bool, xFlipped flipX: Bool, yFlipped flipY: Bool) -> SpriteTexCoordSet {
        var result = SpriteTexCoordSet()
        guard let texture = texture else {
            return result
        }
        // Need to convert the texel coords for the texel stretch hack. (Bah)
        let scale = texture.contentScale
        let rect = rect.scaled(by: scale)
        let sizeInPixels = texture.sizeInPixels
        let atlasWidth = sizeInPixels.width
        let atlasHeight = sizeInPixels.height

        if rotated {
            var left   = rect.origin.x / atlasWidth
            var right  = (rect.origin.x + rect.size.height) / atlasWidth
            var bottom = rect.origin.y / atlasHeight
            var top    = (rect.origin.y + rect.size.width) / atlasHeight
            
            if flipX {
                swap(&top, &bottom)
            }
            if flipY {
                swap(&left, &right)
            }
            result.bl = vec2(left, top)
            result.br = vec2(left, bottom)
            result.tr = vec2(right, bottom)
            result.tl = vec2(right, top)
        }
        else {
            var left   = rect.origin.x / atlasWidth
            var right  = (rect.origin.x + rect.size.width) / atlasWidth
            var bottom = rect.origin.y / atlasHeight
            var top    = (rect.origin.y + rect.size.height) / atlasHeight
            
            if flipX {
                swap(&left, &right)
            }
            if flipY {
                swap(&top, &bottom)
            }
            result.bl = vec2(left, bottom)
            result.br = vec2(right, bottom)
            result.tr = vec2(right, top)
            result.tl = vec2(left, top)
        }
        return result
    }
}
