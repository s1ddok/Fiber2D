//
//  Sprite9Slice.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath
import SwiftBGFX

/**
 Sprite9Slice will render an image in nine quads, keeping the margins fixed and stretching the center quad to fit the content size.
 The effect is that the image's borders will remain unstretched while the center stretches.
 */
open class Sprite9Slice: Sprite {
    /// @name Setting the Margin
    
    /**
     Sets the margin as a normalized percentage of the total image size.
     If set to 0.25, 25% of the left, right, top and bottom borders of the image will remain unstretched.
     
     @note Margin must be in the range 0.0 to below 0.5.
     */
    public var margin : Float {
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
    public var marginLeft:   Float = 0.0
    
    /** Adjusts the margin only for this border.
     @note The sum of the this border's margin plus its opposing border's margin must not be equal to or greater than 1.0! */
    public var marginRight:  Float = 0.0
    
    /** Adjusts the margin only for this border.
     @note The sum of the this border's margin plus its opposing border's margin must not be equal to or greater than 1.0! */
    public var marginTop:    Float = 0.0
    
    /** Adjusts the margin only for this border.
     @note The sum of the this border's margin plus its opposing border's margin must not be equal to or greater than 1.0! */
    public var marginBottom: Float = 0.0
    
    override init(texture: Texture!, rect: Rect, rotated: Bool) {
        super.init(texture: texture, rect: rect, rotated: rotated)
        self.originalContentSize = self.contentSizeInPoints
        // initialize new parts in 9slice
        self.margin = SPRITE_9SLICE_MARGIN_DEFAULT
    }
    
    // TODO This is sort of brute force. Could probably use some optimization after profiling.
    // Could it be done in a vertex shader using the texCoord2 attribute?
    override func draw(_ renderer: Renderer, transform: Matrix4x4f) {
        // Don't draw rects that were originally sizeless. CCButtons in tableviews are like this.
        // Not really sure it's intended behavior or not.
        if originalContentSize.width == 0 && originalContentSize.height == 0 {
            return
        }
        let size     = self.contentSizeInPoints
        let rectSize = self.textureRect.size
        let physicalSize: Size = size + rectSize - originalContentSize
        
        // Lookup tables for alpha coefficients.
        let scaleX = Float(physicalSize.width / rectSize.width)
        let scaleY = Float(physicalSize.height / rectSize.height)
        let alphaX:    [Float] = [0.0, marginLeft, scaleX - marginRight, scaleX]
        let alphaY:    [Float] = [0.0, marginBottom, scaleY - marginTop, scaleY]
        
        let alphaTexX: [Float] = [0.0, marginLeft,   1.0 - marginRight, 1.0]
        let alphaTexY: [Float] = [0.0, marginBottom, 1.0 - marginTop,   1.0]
        // Interpolation matrices for the vertexes and texture coordinates
        let interpolatePosition = PositionInterpolationMatrix(verts, transform: transform)
        let interpolateTexCoord = TexCoordInterpolationMatrix(verts)
        let color = verts.bl.color

        var vertices = [RendererVertex](repeating: RendererVertex(), count: 4 * 4)

        // Interpolate the vertexes!
        for y in 0..<4 {
            for x in 0..<4 {
                let position = interpolatePosition * vec4(alphaX[x], alphaY[y], 0.0, 1.0)
                let texCoord = interpolateTexCoord * vec3(alphaTexX[x], alphaTexY[y], 1.0)
                
                vertices[y * 4 + x] = RendererVertex(position: position,
                                                     texCoord1: vec2(texCoord),
                                                     texCoord2: vec2.zero,
                                                     color: color)
            }
        }
        let vb = TransientVertexBuffer(count: 16, layout: RendererVertex.layout)
        memcpy(vb.data, vertices, 16 * MemoryLayout<RendererVertex>.size)
        bgfx.setVertexBuffer(vb)
        bgfx.setIndexBuffer(Sprite9Slice.indexBuffer)
        
        bgfx.setTexture(0, sampler: uniform, texture: texture.texture)
        bgfx.setRenderState(renderState, colorRgba: 0x00)
        renderer.submit(shader: shader)
    }

    // MARK: Internal stuff
    internal var originalContentSize = Size.zero
    
    public override func setTextureRect(_ rect: Rect, forTexture texture: Texture, rotated: Bool, untrimmedSize: Size) {
        let oldContentSize = self.contentSize
        let oldContentSizeType = self.contentSizeType
        super.setTextureRect(rect, forTexture: self.texture, rotated: rotated, untrimmedSize: untrimmedSize)
        // save the original sizes for texture calculations
        self.originalContentSize = self.contentSizeInPoints
        if oldContentSize != Size.zero {
            self.contentSizeType = oldContentSizeType
            self.contentSize = oldContentSize
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

let SPRITE_9SLICE_MARGIN_DEFAULT: Float = 1.0 / 3.0

internal func PositionInterpolationMatrix(_ verts: SpriteVertexes, transform: Matrix4x4f) -> Matrix4x4f {
    let origin = verts.bl.position
    let basisX = verts.br.position - origin
    let basisY = verts.tl.position - origin
    return transform * Matrix4x4f(vec4(basisX.x, basisX.y, basisX.z, 0.0),
                                  vec4(basisY.x, basisY.y, basisY.z, 0.0),
                                  vec4(0.0, 0.0, 1.0, 0.0),
                                  vec4(origin.x, origin.y, origin.z, 1.0))
}

internal func TexCoordInterpolationMatrix(_ verts: SpriteVertexes) -> Matrix3x3f {
    let origin = verts.bl.texCoord1
    let basisX = verts.br.texCoord1 - origin
    let basisY = verts.tl.texCoord1 - origin
    return Matrix3x3f(vec3(basisX.x, basisX.y, 0.0),
                      vec3(basisY.x, basisY.y, 0.0),
                      vec3(origin.x, origin.y, 1.0))
}
