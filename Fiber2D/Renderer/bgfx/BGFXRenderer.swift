//
//  BGFXRenderer.swift
//  Fiber2D
//
//  Created by Stuart Carnie on 9/11/16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftBGFX
import SwiftMath

class BGFXRenderer: Renderer {
    
    var projection: Matrix4x4f = Matrix4x4f.identity
    
    var bindings = BGFXBufferBindings()
    
    func enqueueClear(color: vec4) {
        bgfx.setViewClear(viewId: 0, options: [.color, .depth], depth: 0.0, stencil: 0)
    }
    
    func enqueueTriangles(count: UInt, verticesCount: UInt, state: RendererState, globalSortOrder: Int) -> RendererBuffer {
        return bindings.makeView(vertexCount: Int(verticesCount), triangleCount: Int(count))
    }
    
    func prepare(withProjection: Matrix4x4f, framebuffer: FrameBufferObject) {
        let proj = unsafeBitCast(withProjection, to: SwiftMath.Matrix4x4f.self)
        bgfx.setViewTransform(viewId: 0, proj: proj)
    
        let vb = TransientVertexBuffer(count: UInt32(bindings.vertexCount), layout: RendererVertex.layout)
        memcpy(vb.data, bindings.vertices, bindings.vertexCount * MemoryLayout<RendererVertex>.size)
        bgfx.setVertexBuffer(vb)
        
        let ib = TransientIndexBuffer(count: UInt32(bindings.indexCount))
        memcpy(vb.data, bindings.vertices, bindings.indexCount * MemoryLayout<UInt16>.size)
        bgfx.setIndexBuffer(ib)
        
        bgfx.submit(0, program: <#T##Program#>)
    }
    
    func flush() {
        bgfx.frame()
    }
    
    func makeFrameBufferObject() -> FrameBufferObject {
        return SwiftBGFX.FrameBuffer(ratio: .equal, format: .bgra8)
    }
}

struct BGFXBufferBindings {
    var vertices: [RendererVertex]
    var vertexCount: Int
    var indices: [UInt16]
    var indexCount: Int
    
    init() {
        vertices    = [RendererVertex](repeating: RendererVertex(), count: 16*1024)
        vertexCount = 0
        indices     = [UInt16](repeating: 0, count: 1024)
        indexCount  = 0
    }
    
    mutating func makeView(vertexCount: Int, triangleCount: Int) -> View {
        if vertices.capacity < self.vertexCount + vertexCount {
            // Why 1.5? https://github.com/facebook/folly/blob/master/folly/docs/FBVector.md
            vertices.reserveCapacity(Int(Double(vertices.capacity) * 1.5))
        }
        
        if indices.capacity < self.indexCount + triangleCount {
            indices.reserveCapacity(Int(Double(indices.capacity) * 1.5))
        }
        
        return View(buf: self, vertexOffset: vertices.count, vertexCount: vertexCount, indexOffset: indices.count, indexCount: indexCount)
    }
    
    struct View: RendererBuffer {
        var buf: BGFXBufferBindings
        let vertexOffset: Int
        let vertexCount: Int
        let indexOffset: Int
        let indexCount: Int
        
        mutating func setVertex(index: Int, vertex: RendererVertex) {
            buf.vertices[vertexOffset+index] = vertex
        }
        
        mutating func setTriangle(index: Int, v1: UInt16, v2: UInt16, v3: UInt16) {
            buf.indices[(indexOffset+index)*3 + 0] = UInt16(vertexOffset)+v1
            buf.indices[(indexOffset+index)*3 + 1] = UInt16(vertexOffset)+v2
            buf.indices[(indexOffset+index)*3 + 2] = UInt16(vertexOffset)+v3
        }
    }
}

extension SwiftBGFX.FrameBuffer: FrameBufferObject {
    
}

extension RendererVertex {
    static var layout: VertexLayout {
        let l = VertexLayout()
        l.begin()
            .add(attrib: .position, num: 4, type: .float)
            .add(attrib: .texCoord0, num: 2, type: .float)
            .add(attrib: .texCoord1, num: 2, type: .float)
            .add(attrib: .color0, num: 4, type: .float, normalized: true)
            .end()
        
        return l
    }
}
