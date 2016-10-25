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
    
    override func draw(_ renderer: Renderer, transform: Matrix4x4f) {
        var buffer = renderer.enqueueTriangles(count: 2, verticesCount: 4, state: renderState, globalSortOrder: 0)
        
        let w = Float(contentSizeInPoints.width)
        let h = Float(contentSizeInPoints.height)

        buffer.setVertex(index: 0, vertex: RendererVertex(position: transform * vec4(0, 0, 0, 1), texCoord1: vec2.zero, texCoord2: vec2.zero, color: colors))
        buffer.setVertex(index: 1, vertex: RendererVertex(position: transform * vec4(w, 0, 0, 1), texCoord1: vec2.zero, texCoord2: vec2.zero, color: colors))
        buffer.setVertex(index: 2, vertex: RendererVertex(position: transform * vec4(w, h, 0, 1), texCoord1: vec2.zero, texCoord2: vec2.zero, color: colors))
        buffer.setVertex(index: 3, vertex: RendererVertex(position: transform * vec4(0, h, 0, 1), texCoord1: vec2.zero, texCoord2: vec2.zero, color: colors))
        
        buffer.setTriangle(index: 0, v1: 0, v2: 1, v3: 2)
        buffer.setTriangle(index: 1, v1: 0, v2: 2, v3: 3)
    }
}
