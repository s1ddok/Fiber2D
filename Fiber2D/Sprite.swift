//
//  Sprite.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath
import SwiftBGFX

/// The four RendererVertexes of a sprite.
/// Bottom left, bottom right, top right, top left.
public struct SpriteVertexes {
    var bl, br, tr, tl: RendererVertex
    
    public var uv: SpriteTexCoordSet {
        get {
            return SpriteTexCoordSet(bl: bl.texCoord1, br: br.texCoord1,
                                     tr: tr.texCoord1, tl: tl.texCoord1)
        }
        set {
            bl.texCoord1 = newValue.bl
            br.texCoord1 = newValue.br
            tr.texCoord1 = newValue.tr
            tl.texCoord1 = newValue.tl
        }
    }
    
    public var uv2: SpriteTexCoordSet {
        get {
            return SpriteTexCoordSet(bl: bl.texCoord2, br: br.texCoord2,
                                     tr: tr.texCoord2, tl: tl.texCoord2)
        }
        set {
            bl.texCoord2 = newValue.bl
            br.texCoord2 = newValue.br
            tr.texCoord2 = newValue.tr
            tl.texCoord2 = newValue.tl
        }
    }
    
    public var color: Color {
        get {
            return bl.color
        }
        set {
            bl.color = newValue
            br.color = newValue
            tr.color = newValue
            tl.color = newValue
        }
    }
    
    public static let zero = SpriteVertexes(bl: RendererVertex(),
                                            br: RendererVertex(),
                                            tr: RendererVertex(),
                                            tl: RendererVertex())
}

/// A set of four texture coordinates corresponding to the four
/// vertices of a sprite.
public struct SpriteTexCoordSet {
    var bl, br, tr, tl: Vector2f
}

/**
 * Sprite can be created with an image, with a sub-rectangle of an (atlas) image.
 */
public class Sprite {
    
    /**
     * Geometry of the sprite that will be used by a render component
     */
    // Vertex coords, texture coords and color info.
    public var verts = SpriteVertexes.zero
    
    /**
     *  Initializes a sprite with the name of an image. The name can be either a name in a sprite sheet or the name of a file.
     *
     *  @param imageName name of the image to load.
     *
     *  @return A newly initialized Sprite object.
     */
    public convenience init(imageNamed imageName: String) {
        let spriteFrame = SpriteFrame.with(imageName: imageName)
        self.init(spriteFrame: spriteFrame!)
    }
    
    /**
     *  Initializes an sprite with an existing SpriteFrame.
     *  @note This is the designated initializer.
     *
     *  @param spriteFrame Sprite frame to use.
     *
     *  @return A newly initialized Sprite object.
     *  @see SpriteFrame
     */
    public init(spriteFrame: SpriteFrame) {
        self.spriteFrame = spriteFrame
        updateTextureRect()
    }
    
    /**
     *  Initializes a sprite with an existing Texture and a rect in points, optionally rotated.
     *  The offset will be (0,0).
     *
     *  @param texture The texture to use.
     *  @param rect    The rect to use.
     *  @param rotated YES if texture is rotated.
     *
     *  @return A newly initialized Sprite object.
     *  @see Texture
     */
    public convenience init(texture: Texture, rect: Rect? = nil, rotated: Bool = false) {
        // default transform anchor: center
        let spriteFrame = SpriteFrame(texture: texture,
                                      rect: rect ?? Rect(size: texture.contentSize),
                                      rotated: rotated,
                                      trimOffset: .zero,
                                      untrimmedSize: texture.contentSize)
        self.init(spriteFrame: spriteFrame)
    }
    
    /// @name Flipping a Sprite
    
    /** Whether or not the sprite is flipped horizontally.
     @note Flipping does not flip any of the sprite's child sprites nor does it alter the anchorPoint.
     If that is what you want, you should try inversing the Node scaleX property: `sprite.scaleX *= -1.0;`.
     */
    public var flipX: Bool = false {
        didSet {
            if flipX != oldValue {
                updateTextureRect()
            }
        }
    }
    
    /** Whether or not the sprite is flipped vertically.
     @note Flipping does not flip any of the sprite's child sprites nor does it alter the anchorPoint.
     If that is what you want, you should try inversing the Node scaleY property: `sprite.scaleY *= -1.0;`.
     */
    public var flipY: Bool = false {
        didSet {
            if flipY != oldValue {
                updateTextureRect()
            }
        }
    }
    
    /// @name Accessing the Sprite Frames
    
    /** The currently displayed spriteFrame.
     @see SpriteFrame */
    public var spriteFrame: SpriteFrame {
        didSet {
            updateTextureRect()
            onSpriteFrameChanged.fire(spriteFrame)
        }
    }
    
    /** The secondary spriteFrame used by effect shaders. (Ex: Custom shaders or normal mapping)
     @see SpriteFrame */
    public var spriteFrame2: SpriteFrame? {
        didSet {
            guard let spriteFrame2 = spriteFrame2 else {
                return
            }
            let secondaryTexture = spriteFrame2.texture
            // Set the second texture coordinate set from the normal map's sprite frame.
            verts.uv2 = secondaryTexture.uv(for: spriteFrame2.rect, rotated: spriteFrame2.isRotated, xFlipped: flipX, yFlipped: flipY)
        }
    }
    
    /// @name Working with the Sprite's Texture
    
    /** The offset position in points of the sprite in points. Calculated automatically by sprite sheet editors. */
    private(set) public var offsetPosition = Point.zero
    
    /** Returns the texture rect of the Sprite in points. */
    private(set) public var textureRect = Rect.zero
    
    /**
     *  Set the texture rect, rectRotated and untrimmed size of the Sprite in points.
     *  It will update the texture coordinates and the vertex rectangle.
     */
    public func updateTextureRect() {
        let rect = spriteFrame.rect
        let texture = spriteFrame.texture
        let rotated = spriteFrame.isRotated
        let untrimmedSize = spriteFrame.untrimmedSize
        self.textureRect = rect
        
        verts.uv = texture.uv(for: rect, rotated: rotated, xFlipped: flipX, yFlipped: flipY)

        var relativeOffset = spriteFrame.trimOffset
        // issue #732
        if flipX {
            relativeOffset.x = -relativeOffset.x
        }
        if flipY {
            relativeOffset.y = -relativeOffset.y
        }
        
        self.offsetPosition = relativeOffset + (untrimmedSize - textureRect.size) * 0.5

        // Atlas: Vertex
        let x1 = offsetPosition.x
        let y1 = offsetPosition.y
        let x2 = x1 + textureRect.size.width
        let y2 = y1 + textureRect.size.height
        
        verts.bl.position = vec4(x1, y1, 0.0, 1.0)
        verts.br.position = vec4(x2, y1, 0.0, 1.0)
        verts.tr.position = vec4(x2, y2, 0.0, 1.0)
        verts.tl.position = vec4(x1, y2, 0.0, 1.0)
        // Set the center/extents for culling purposes.
        self.vertexCenter = vec2((x1 + x2) * 0.5, (y1 + y2) * 0.5)
        self.vertexExtents = vec2((x2 - x1) * 0.5, (y2 - y1) * 0.5)
    }
    
    /** Returns the matrix that transforms the sprite's (local) space coordinates into the sprite's texture space coordinates.
     */
    public var nodeToTextureTransform: Matrix4x4f {
        let bl = verts.bl,
            br = verts.br,
            tl = verts.tl
        
        let sx = (br.texCoord1.s - bl.texCoord1.s) / (br.position.x - bl.position.x)
        let sy = (tl.texCoord1.t - bl.texCoord1.t) / (tl.position.y - bl.position.y)
        let tx = bl.texCoord1.s - bl.position.x * sx
        let ty = bl.texCoord1.t - bl.position.y * sy
        return Matrix4x4f(vec4(sx, 0.0, 0.0, 0.0),
                          vec4(0.0, sy, 0.0, 0.0),
                          vec4(0.0, 0.0, 1.0, 0.0),
                          vec4(tx, ty, 0.0, 1.0))
    }

    // MARK: Events
    public let onSpriteFrameChanged = Event<SpriteFrame>()
    
    // MARK: Internal stuff

    // Center of extents (half width/height) of the sprite for culling purposes.
    internal var vertexCenter = vec2.zero
    internal var vertexExtents = vec2.zero
}

/**
 * This render component should be used to draw sprites on Nodes
 *
 * @note this component adjusts Node's contentSizeInPoints as Sprite's sprite frame changes
 */
public class SpriteRenderComponent: ComponentBase, RenderComponent {
    public var material = Material(technique: .positionTexture)
    
    public init(sprite: Sprite) {
        super.init()
        self.sprite = sprite
        self.material.set(texture: sprite.spriteFrame.texture, unit: 0, name: ShaderUniformMainTexture)
        
        sprite.onSpriteFrameChanged.subscribe(on: self) {
            self.material.set(texture: $0.texture, unit: 0, name: ShaderUniformMainTexture)
            self.owner?.contentSizeInPoints = $0.untrimmedSize
        }
    }
    
    public var sprite: Sprite? {
        didSet {
            oldValue?.onSpriteFrameChanged.cancelSubscription(for: self)
        }
    }
    
    public override func onAdd(to owner: Node) {
        super.onAdd(to: owner)
  
        self.sprite?.verts.color = owner.displayedColor.premultiplyingAlpha
        owner.onDisplayedColorChanged.subscribe(on: self) {
            self.sprite?.verts.color = $0.premultiplyingAlpha
        }
    }
    
    public override func onRemove() {
        // Do it before super, as it assigns owner to nil
        owner?.onDisplayedColorChanged.cancelSubscription(for: self)
        super.onRemove()
    }

    public func draw(in renderer: Renderer, transform: Matrix4x4f) {
        // Do not perform anything if we do not have any sprite assigned
        guard let sprite = sprite else {
            return
        }
        let verts = sprite.verts
        let vertices = [verts.bl.transformed(transform),
                        verts.br.transformed(transform),
                        verts.tr.transformed(transform),
                        verts.tl.transformed(transform)]
        let vb = TransientVertexBuffer(count: 4, layout: RendererVertex.layout)
        memcpy(vb.data, vertices, 4 * MemoryLayout<RendererVertex>.size)
        
        for pass in material.technique.passes {
            material.apply()
            bgfx.setVertexBuffer(vb)
            bgfx.setIndexBuffer(QuadRenderer.indexBuffer)
            bgfx.setRenderState(pass.renderState, colorRgba: 0x0)
            renderer.submit(shader: pass.program)
        }
    }
}
