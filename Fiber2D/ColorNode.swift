//
//  ColorNode.swift
//
//  Created by Andrey Volodin on 06.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath
import SwiftBGFX
import Darwin

/**
 Draws a rectangle filled with a solid color.
 */
open class ColorNode: Node {
    internal var colors = Color.clear
    
    public var material: Material
    
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
        self.material = Material(technique: .positionColor)
        super.init()
        self.color = color
        self.contentSizeInPoints = size
        
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
        let s = contentSizeInPoints
        let w = s.width
        let h = s.height

        let vertices = [
            RendererVertex(position: transform * vec4(0, 0, 0, 1),
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

        let ib = TransientIndexBuffer(count: 6)
        let indices: [UInt16] = [0, 1, 2, 0, 2, 3]
        memcpy(ib.data, indices, 6 * MemoryLayout<UInt16>.size)
        
        for pass in material.technique.passes {
            material.apply()
            bgfx.setVertexBuffer(vb)
            bgfx.setIndexBuffer(ib)
            bgfx.setRenderState(pass.renderState, colorRgba: 0x0)
            renderer.submit(shader: pass.program)
        }
    }
}
