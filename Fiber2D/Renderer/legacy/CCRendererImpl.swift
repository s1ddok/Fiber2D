//
//  CCRendererImpl.swift
//  Fiber2D
//
//  Created by Stuart Carnie on 9/11/16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

class CCRendererImpl: Renderer {
    public var projection: Matrix4x4f {
        get {
            var projection = Matrix4x4f.identity
            (renderer.globalShaderUniforms[CCShaderUniformProjection]! as! NSValue).getValue(&projection)
            return projection
        }
    }

    let renderer: CCRenderer
    
    init(renderer: CCRenderer) {
        self.renderer = renderer
    }
    
    func enqueueClear(color: Color) {
        renderer.enqueueClear(.clear, color: color.glkVector4, globalSortOrder: Int.min)
    }
    
    func enqueueTriangles(count: UInt, verticesCount: UInt, state: RendererState, globalSortOrder: Int) -> RendererBuffer {
        return renderer.enqueueTriangles(count, andVertexes: verticesCount, with: state as! CCRenderState, globalSortOrder: globalSortOrder)
    }
    
    func prepare(withProjection: Matrix4x4f, framebuffer: FrameBufferObject) {
        var proj = withProjection.glkMatrix4
        renderer.prepare(withProjection: &proj, framebuffer: framebuffer as! CCFrameBufferObject)
    }
    
    func flush() {
        renderer.flush()
    }
    
    func makeFrameBufferObject() -> FrameBufferObject {
        return CCFrameBufferObject()
    }
}

extension CCRenderState: RendererState {
    
}

extension CCRenderBuffer: RendererBuffer {
    public mutating func setVertex(index: Int, vertex: RendererVertex) {
        CCRenderBufferSetVertex(self, Int32(index), unsafeBitCast(vertex, to: CCVertex.self))
    }
    
    public mutating func setTriangle(index: Int, v1: UInt16, v2: UInt16, v3: UInt16) {
        CCRenderBufferSetTriangle(self, Int32(index), v1, v2, v3)
    }
}

extension CCFrameBufferObject: FrameBufferObject {
    
}


