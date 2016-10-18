//
//  ColorNode.swift
//
//  Created by Andrey Volodin on 06.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

/**
 Draws a rectangle filled with a solid color.
 */
open class ColorNode: RenderableNode {
    internal var colors = Color.clear
    /**
     *  Creates a node with color, width and height in Points.
     *
     *  @param color Color of the node.
     *  @param size  Width and Height of the node.
     *
     *  @return An initialized ColorNode Object.
     *  @see Color
     */
    public init(color: Color = .clear, size: Size = .zero) {
        super.init()
        self.color = color
        self.contentSizeInPoints = size
        
        self.blendMode = CCBlendMode.premultipliedAlpha()
        self.shader = CCShader.positionColor()
        
        updateColor()
    }
    
    override var color: Color {
        didSet {
           updateColor()
        }
    }
    
    override var opacity: Float {
        didSet {
            updateColor()
        }
    }
    
    override func updateDisplayedOpacity(_ parentOpacity: Float) {
        super.updateDisplayedOpacity(parentOpacity)
        updateColor()
    }
    
    internal func updateColor() {
        colors = displayedColor.premultiplyingAlpha
    }
    
    override func draw(_ renderer: CCRenderer, transform: Matrix4x4f) {
        let buffer = renderer.enqueueTriangles(2, andVertexes: 4, with: renderState, globalSortOrder: 0)
        
        let w = Float(contentSizeInPoints.width)
        let h = Float(contentSizeInPoints.height)
        let zero = GLKVector2(v: (0.0, 0.0))
        
        let col = colors.glkVector4
        let transform = transform.glkMatrix4
        
        CCRenderBufferSetVertex(buffer, 0, CCVertex(position: GLKMatrix4MultiplyVector4(transform, GLKVector4Make(0, 0, 0, 1)), texCoord1: zero, texCoord2: zero, color: col));
        CCRenderBufferSetVertex(buffer, 1, CCVertex(position: GLKMatrix4MultiplyVector4(transform, GLKVector4Make(w, 0, 0, 1)), texCoord1: zero, texCoord2: zero, color: col));
        CCRenderBufferSetVertex(buffer, 2, CCVertex(position: GLKMatrix4MultiplyVector4(transform, GLKVector4Make(w, h, 0, 1)), texCoord1: zero, texCoord2: zero, color: col));
        CCRenderBufferSetVertex(buffer, 3, CCVertex(position: GLKMatrix4MultiplyVector4(transform, GLKVector4Make(0, h, 0, 1)), texCoord1: zero, texCoord2: zero, color: col));
        
        CCRenderBufferSetTriangle(buffer, 0, 0, 1, 2)
        CCRenderBufferSetTriangle(buffer, 1, 0, 2, 3)
    }
}
