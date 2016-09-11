//
//  Renderer.swift
//  Fiber2D
//
//  Created by Stuart Carnie on 9/8/16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public protocol Renderer {
    func enqueueClear(color: vec4, globalSortOrder: Int)
    func enqueueTriangles(count: UInt, verticesCount: UInt, state: RendererState, globalSortOrder: Int) -> RendererBuffer
    func prepare(withProjection: Matrix4x4f, framebuffer: FrameBufferObject)
    func flush()
    
    // MARK: - render objects
    func makeFrameBufferObject() -> FrameBufferObject
    
    var projection: Matrix4x4f { get }
}

var currentRenderer: Renderer?

public protocol RendererState {
    
}

public protocol FrameBufferObject {
}

public protocol RendererBuffer {
    func setVertex(index: Int, vertex: RendererVertex)
    func setTriangle(index: Int, v1: Int, v2: Int, v3: Int)
}

public struct RendererVertex {
    var position: vec4
    var texCoord1, texCoord2: vec2
    var color: vec4;
    
    public init() {
        position = vec4(0)
        texCoord1 = vec2.zero
        texCoord2 = vec2.zero
        color = vec4(0)
    }
    
    public init(position: vec4, texCoord1: vec2, texCoord2: vec2, color: vec4) {
        self.position = position
        self.texCoord1 = texCoord1
        self.texCoord2 = texCoord2
        self.color = color
    }
    
    public func transformed(_ m: Matrix4x4f) -> RendererVertex {
        return RendererVertex(position: m * position, texCoord1: texCoord1, texCoord2: texCoord2, color: color)
    }
}
