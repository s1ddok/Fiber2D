//
//  RenderComponent.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 03.12.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath
import SwiftBGFX

/**
 * Base protocol for all render components
 *
 * All render components must have material.
 */
public protocol RenderableComponent: Component {
    var material: Material { get set }
    
    /**
     Implement this method to add custom rendering code to your node.
     
     @note You should only use Fiber2D's Renderer API to modify the render state and shaders. For further info, please see the Renderer documentation.
     @warning You **must not** call `super.draw(in:transform:)`
     
     @param renderer The Renderer instance to use for drawing.
     @param transform The parent node's transform.
     @see Renderer
     */
    func draw(in renderer: Renderer, transform: Matrix4x4f)
}

//
// MARK: Default renderers
//
public class QuadRenderer: ComponentBase, RenderableComponent {
    public var material: Material
    
    /// Geometry to be rendered. 
    /// Must be exactly 4 vertices long, index buffer is ignored
    public var geometry = Geometry(vertexBuffer: [RendererVertex](repeating: RendererVertex(),
                                                                  count: 4),
                                   indexBuffer: [])
    
    public init(material: Material) {
        self.material = material
        super.init()
    }
    
    public func draw(in renderer: Renderer, transform: Matrix4x4f) {
        let vertices = geometry.vertexBuffer.map { $0.transformed(transform) }
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
    
    public static let indexBuffer: IndexBuffer = {
        // We have 2 triangles, 6 indices
        let retVal: [UInt16] = [0, 1, 2, 0, 2, 3]
        let memory = MemoryBlock(data: retVal)
        return IndexBuffer(memory: memory)
    }()
}
