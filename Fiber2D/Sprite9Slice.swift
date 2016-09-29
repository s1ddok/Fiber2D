//
//  Sprite9Slice.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

let SPRITE_9SLICE_MARGIN_DEFAULT: Float = 1.0 / 3.0

func PositionInterpolationMatrix(_ verts: inout SpriteVertexes, transform: GLKMatrix4) -> GLKMatrix4 {
    let origin: GLKVector4 = verts.bl.position
    let basisX: GLKVector4 = GLKVector4Subtract(verts.br.position, origin)
    let basisY: GLKVector4 = GLKVector4Subtract(verts.tl.position, origin)
    return GLKMatrix4Multiply(transform, GLKMatrix4Make(basisX.x, basisX.y, basisX.z, 0.0, basisY.x, basisY.y, basisY.z, 0.0, 0.0, 0.0, 1.0, 0.0, origin.x, origin.y, origin.z, 1.0))
}
func TexCoordInterpolationMatrix(_ verts: inout SpriteVertexes) -> GLKMatrix3 {
    let origin: GLKVector2 = verts.bl.texCoord1
    let basisX: GLKVector2 = GLKVector2Subtract(verts.br.texCoord1, origin)
    let basisY: GLKVector2 = GLKVector2Subtract(verts.tl.texCoord1, origin)
    return GLKMatrix3Make(basisX.x, basisX.y, 0.0, basisY.x, basisY.y, 0.0, origin.x, origin.y, 1.0)
}

@objc class Sprite9Slice : Sprite {
    var originalContentSize = Size.zero
    
    var margin : Float {
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
    
    // TODO Add clamping and assertions
    var marginLeft: Float = 0.0
    var marginRight: Float = 0.0
    var marginTop: Float = 0.0
    var marginBottom: Float = 0.0
    
    override init(texture: CCTexture!, rect: Rect, rotated: Bool) {
        super.init(texture: texture, rect: rect, rotated: rotated)
        self.originalContentSize = self.contentSizeInPoints
        // initialize new parts in 9slice
        self.margin = SPRITE_9SLICE_MARGIN_DEFAULT
    }
    
    func setTextureRect(_ rect: Rect, rotated: Bool, untrimmedSize: Size) {
        let oldContentSize = self.contentSize
        let oldContentSizeType = self.contentSizeType
        self.setTextureRect(rect, forTexture: self.texture, rotated: rotated, untrimmedSize: untrimmedSize)
        // save the original sizes for texture calculations
        self.originalContentSize = self.contentSizeInPoints
        if oldContentSize != Size.zero {
            self.contentSizeType = oldContentSizeType
            self.contentSize = oldContentSize
        }
    }
    // TODO This is sort of brute force. Could probably use some optimization after profiling.
    // Could it be done in a vertex shader using the texCoord2 attribute?
    
    override func draw(_ renderer: CCRenderer, transform: Matrix4x4f) {
        // Don't draw rects that were originally sizeless. CCButtons in tableviews are like this.
        // Not really sure it's intended behavior or not.
        if originalContentSize.width == 0 && originalContentSize.height == 0 {
            return
        }
        let size: Size = self.contentSizeInPoints
        let rectSize: Size = self.textureRect.size
        let physicalSize: Size = Size(width: size.width + rectSize.width - originalContentSize.width, height: size.height + rectSize.height - originalContentSize.height)
        // Lookup tables for alpha coefficients.
        let scaleX = Float(physicalSize.width / rectSize.width)
        let scaleY = Float(physicalSize.height / rectSize.height)
        let alphaX:    [Float] = [0.0, marginLeft, scaleX - marginRight, scaleX]
        let alphaY:    [Float] = [0.0, marginBottom, scaleY - marginTop, scaleY]
        
        let alphaTexX: [Float] = [0.0, marginLeft, 1.0 - marginRight, 1.0]
        let alphaTexY: [Float] = [0.0, marginBottom, 1.0 - marginTop, 1.0]
        // Interpolation matrices for the vertexes and texture coordinates
        let interpolatePosition: GLKMatrix4 = PositionInterpolationMatrix(&verts, transform: transform.glkMatrix4)
        let interpolateTexCoord: GLKMatrix3 = TexCoordInterpolationMatrix(&verts)
        let color: GLKVector4 = verts.bl.color
        let buffer: CCRenderBuffer = renderer.enqueueTriangles(18, andVertexes: 16, with: self.renderState, globalSortOrder: 0)
        
        // Interpolate the vertexes!
        for y in 0..<4 {
            for x in 0..<4 {
                let position: GLKVector4 = GLKMatrix4MultiplyVector4(interpolatePosition, GLKVector4Make(alphaX[x], alphaY[y], 0.0, 1.0))
                var texCoord: GLKVector3 = GLKMatrix3MultiplyVector3(interpolateTexCoord, GLKVector3Make(alphaTexX[x], alphaTexY[y], 1.0))
                CCRenderBufferSetVertex(buffer, Int32(y * 4 + x), CCVertex(position: position,
                    texCoord1: GLKVector2Make(texCoord.v.0, texCoord.v.1),
                    texCoord2: GLKVector2Make(0.0, 0.0),
                    color: color))
            }
        }
        // Output lots of triangles.
        for y in 0..<3 {
            for x in 0..<3 {
                CCRenderBufferSetTriangle(buffer,
                                          Int32(y * 6 + x * 2),
                                          UInt16(y * 4 + x),
                                          UInt16(y * 4 + x + 1),
                                          UInt16((y + 1) * 4 + x + 1))
                CCRenderBufferSetTriangle(buffer,
                                          Int32(y * 6 + x * 2 + 1),
                                          UInt16(y * 4 + x),
                                          UInt16((y + 1) * 4 + x + 1),
                                          UInt16((y + 1) * 4 + x))
            }
        }
    }


}
