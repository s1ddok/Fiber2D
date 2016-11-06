//
//  ColorNode.swift
//
//  Created by Andrey Volodin on 06.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath
import SwiftBGFX

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
        
        self.blendMode = .premultipliedAlphaMode
        
        updateColor()
    }
    
    override public var color: Color {
        didSet {
            updateColor()
        }
    }
    
    override public var opacity: Float {
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
        
        let w = Float(contentSizeInPoints.width)
        let h = Float(contentSizeInPoints.height)

        let vertices = [RendererVertex(position: transform * vec4(0, 0, 0, 1),
                                       texCoord1: vec2.zero, texCoord2: vec2.zero,
                                       color: colors),
            RendererVertex(position: transform * vec4(w, 0, 0, 1),
                                       texCoord1: vec2.zero, texCoord2: vec2.zero,
                                       color: colors),
            RendererVertex(position: transform * vec4(w, h, 0, 1),
                           texCoord1: vec2.zero, texCoord2: vec2.zero,
                           color: colors),
            RendererVertex(position: transform * vec4(0, h, 0, 1),
                           texCoord1: vec2.zero, texCoord2: vec2.zero,
                           color: colors)]
        
        let vb = TransientVertexBuffer(count: 4, layout: RendererVertex.layout)
        memcpy(vb.data, vertices, 4 * MemoryLayout<RendererVertex>.size)
        bgfx.setVertexBuffer(vb)
        
        let ib = TransientIndexBuffer(count: 6)
        let indices: [UInt16] = [0, 1, 2, 0, 2, 3]
        memcpy(ib.data, indices, 6 * MemoryLayout<UInt16>.size)
        bgfx.setIndexBuffer(ib)
        bgfx.setRenderState(renderState, colorRgba: 0x00)
        renderer.submit(shader: shader)
    }
}
