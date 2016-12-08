//
//  Sprite9Slice.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath
import SwiftBGFX

internal let SPRITE_9SLICE_MARGIN_DEFAULT: Float = 1.0 / 3.0

/**
 Sprite9Slice will render an image in nine quads, keeping the margins fixed and stretching the center quad to fit the content size.
 The effect is that the image's borders will remain unstretched while the center stretches.
 */
public class Sprite9Slice: Sprite {
    override public init(spriteFrame: SpriteFrame) {
        super.init(spriteFrame: spriteFrame)
        self.originalContentSize = spriteFrame.untrimmedSize
        
        // initialize new parts in 9slice
        self.margin = SPRITE_9SLICE_MARGIN_DEFAULT
    }
    
    /// @name Setting the Margin
    
    /**
     Sets the margin as a normalized percentage of the total image size.
     If set to 0.25, 25% of the left, right, top and bottom borders of the image will remain unstretched.
     
     @note Margin must be in the range 0.0 to below 0.5.
     */
    public var margin: Float {
        get {
            return (marginLeft == marginRight && marginLeft == marginTop && marginLeft == marginBottom) ? marginLeft : 0.0
        }
        set {
            let clampedMargin = newValue
            self.marginLeft = clampedMargin
            self.marginRight = clampedMargin
            self.marginTop = clampedMargin
            self.marginBottom = clampedMargin
        }
    }
    
    /// @name Individual Margins
    
    /** Adjusts the margin only for this border.
     @note The sum of the this border's margin plus its opposing border's margin must not be equal to or greater than 1.0! */
    public var marginLeft:   Float = 0.0 {
        didSet {
            isGeometryNeedsUpdate = true
        }
    }
    
    /** Adjusts the margin only for this border.
     @note The sum of the this border's margin plus its opposing border's margin must not be equal to or greater than 1.0! */
    public var marginRight:  Float = 0.0 {
        didSet {
            isGeometryNeedsUpdate = true
        }
    }
    
    /** Adjusts the margin only for this border.
     @note The sum of the this border's margin plus its opposing border's margin must not be equal to or greater than 1.0! */
    public var marginTop:    Float = 0.0 {
        didSet {
            isGeometryNeedsUpdate = true
        }
    }
    
    /** Adjusts the margin only for this border.
     @note The sum of the this border's margin plus its opposing border's margin must not be equal to or greater than 1.0! */
    public var marginBottom: Float = 0.0 {
        didSet {
            isGeometryNeedsUpdate = true
        }
    }
    
    override public var spriteFrame: SpriteFrame {
        didSet {
            originalContentSize = spriteFrame.untrimmedSize
            isGeometryNeedsUpdate = true
        }
    }
    
    override public var spriteFrame2: SpriteFrame? {
        didSet {
            isGeometryNeedsUpdate = true
        }
    }
    
    // MARK: Internal stuff
    internal var originalContentSize = Size.zero
    internal var geometryColor       = Color.clear {
        didSet {
            isGeometryNeedsUpdate = true
        }
    }
    internal var contentSize         = Size.zero {
        didSet {
            isGeometryNeedsUpdate = true
        }
    }
    internal var isGeometryNeedsUpdate = true
    
    public var geometry: Geometry {
        if isGeometryNeedsUpdate {
            // TODO: This is sort of brute force. Could probably use some optimization after profiling.
            // Could it be done in a vertex shader using the texCoord2 attribute?
            let size     = self.contentSize
            let rectSize = self.textureRect.size
            let physicalSize = size + rectSize - originalContentSize
            
            // Lookup tables for alpha coefficients.
            let scaleX = physicalSize.width / rectSize.width
            let scaleY = physicalSize.height / rectSize.height
            let alphaX:    [Float] = [0.0, marginLeft,   scaleX - marginRight, scaleX]
            let alphaY:    [Float] = [0.0, marginBottom, scaleY - marginTop,   scaleY]
            
            let alphaTexX: [Float] = [0.0, marginLeft,   1.0 - marginRight, 1.0]
            let alphaTexY: [Float] = [0.0, marginBottom, 1.0 - marginTop,   1.0]
            // Interpolation matrices for the vertexes and texture coordinates
            let interpolatePosition = verts.positionInterpolationMatrix
            let interpolateTexCoord = verts.texCoordInterpolationMatrix
            
            var vertices = [RendererVertex](repeating: RendererVertex(), count: 4 * 4)
            
            // Interpolate the vertexes!
            for y in 0..<4 {
                for x in 0..<4 {
                    let position = interpolatePosition * vec4(alphaX[x], alphaY[y], 0.0, 1.0)
                    let texCoord = interpolateTexCoord * vec3(alphaTexX[x], alphaTexY[y], 1.0)
                    
                    vertices[y * 4 + x] = RendererVertex(position: position,
                                                         texCoord1: vec2(texCoord),
                                                         texCoord2: vec2.zero,
                                                         color: geometryColor)
                }
            }

            _geometry = Geometry(vertexBuffer: vertices, indexBuffer: [])
            isGeometryNeedsUpdate = false
        }
        return _geometry
    }
    
    internal var _geometry = Geometry(vertexBuffer: [], indexBuffer: [])
}

internal extension SpriteVertexes {
    internal var positionInterpolationMatrix: Matrix4x4f {
        let origin = bl.position
        let basisX = br.position - origin
        let basisY = tl.position - origin
        return Matrix4x4f(vec4(basisX.x, basisX.y, basisX.z, 0.0),
                          vec4(basisY.x, basisY.y, basisY.z, 0.0),
                          vec4(0.0, 0.0, 1.0, 0.0),
                          vec4(origin.x, origin.y, origin.z, 1.0))
    }
    
    internal var texCoordInterpolationMatrix: Matrix3x3f {
        let origin = bl.texCoord1
        let basisX = br.texCoord1 - origin
        let basisY = tl.texCoord1 - origin
        return Matrix3x3f(vec3(basisX.x, basisX.y, 0.0),
                          vec3(basisY.x, basisY.y, 0.0),
                          vec3(origin.x, origin.y, 1.0))
    }
}

public class Sprite9SliceRenderComponent: ComponentBase, RenderableComponent {
    public var material = Material(technique: .positionTexture)
    public var zOrder: Int = 0
    
    public var sprite: Sprite9Slice? {
        didSet {
            oldValue?.onSpriteFrameChanged.cancelSubscription(for: self)
        }
    }
    
    public init(sprite: Sprite9Slice) {
        super.init()
        self.sprite = sprite
        
        self.material.set(texture: sprite.spriteFrame.texture, unit: 0, name: ShaderUniformMainTexture)
        sprite.onSpriteFrameChanged.subscribe(on: self) {
            self.material.set(texture: $0.texture, unit: 0, name: ShaderUniformMainTexture)
        }
    }
    
    public override func onAdd(to owner: Node) {
        super.onAdd(to: owner)
        
        self.sprite?.contentSize = owner.contentSizeInPoints
        owner.onContentSizeInPointsChanged.subscribe(on: self) {
            self.sprite?.contentSize = $0
        }
        
        self.sprite?.geometryColor = owner.displayedColor.premultiplyingAlpha
        owner.onDisplayedColorChanged.subscribe(on: self) {
            self.sprite?.geometryColor = $0.premultiplyingAlpha
        }
    }
    
    public override func onRemove() {
        // Do it before super, as it assigns owner to nil
        owner?.onContentSizeInPointsChanged.cancelSubscription(for: self)
        owner?.onDisplayedColorChanged.cancelSubscription(for: self)
        super.onRemove()
    }
    
    public func draw(in renderer: Renderer, transform: Matrix4x4f) {
        guard let sprite = sprite else {
            return
        }
        
        let vertices = sprite.geometry.vertexBuffer.map { $0.transformed(transform) }
        let vb = TransientVertexBuffer(count: UInt32(vertices.count), layout: RendererVertex.layout)
        memcpy(vb.data, vertices, vertices.count * MemoryLayout<RendererVertex>.size)
        
        for pass in material.technique.passes {
            material.apply()
            bgfx.setVertexBuffer(vb)
            bgfx.setIndexBuffer(Sprite9SliceRenderComponent.indexBuffer)
            bgfx.setRenderState(pass.renderState, colorRgba: 0x0)
            renderer.submit(shader: pass.program)
        }
    }
    
    internal static let indexBuffer: IndexBuffer = {
        // We have 18 triangles
        var retVal = [UInt16](repeating: 0, count: 18 * 3)
        
        // Output lots of triangles.
        for y: UInt16 in 0..<3 {
            for x: UInt16 in 0..<3 {
                let triIdx1 = Int(y * 6 + x * 2 + 0)
                retVal[3 * triIdx1 + 0] = y * 4 + x
                retVal[3 * triIdx1 + 1] = y * 4 + x + 1
                retVal[3 * triIdx1 + 2] = (y + 1) * 4 + x + 1
                
                let triIdx2 = Int(y * 6 + x * 2 + 1)
                retVal[3 * triIdx2 + 0] = y * 4 + x
                retVal[3 * triIdx2 + 1] = (y + 1) * 4 + x + 1
                retVal[3 * triIdx2 + 2] = (y + 1) * 4 + x
            }
        }
        
        let memory = MemoryBlock(data: retVal)
        return IndexBuffer(memory: memory)
    }()
    
}
