//
//  Renderer.swift
//  Fiber2D
//
//  Created by Stuart Carnie on 9/8/16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath
import SwiftBGFX

// All there requires more consideration
public protocol Renderer {
    // TODO: Abstract from SwiftBGFX
    func submit(shader: Program)
    func enqueueClear(color: vec4)
    func prepare(withProjection: Matrix4x4f)
    func flush()
    
    // MARK: - render objects
    func makeFrameBufferObject() -> FrameBufferObject
    func beginRenderTexture(_ rt: RenderTexture)
    func endRenderTexture()
    
    // TODO: Push group, pop group
    // TODO: Compute shader support
}

var currentRenderer: Renderer?

public protocol RendererState {
    
}

public protocol FrameBufferObject {
}

public protocol RendererBuffer {
    mutating func setVertex(index: Int, vertex: RendererVertex)
    mutating func setTriangle(index: Int, v1: UInt16, v2: UInt16, v3: UInt16)
}

public struct RendererVertex {
    var position: Vector4f
    var texCoord1, texCoord2: Vector2f
    var color: Vector4f
    
    public init() {
        position = vec4(0)
        texCoord1 = vec2.zero
        texCoord2 = vec2.zero
        color = vec4(0)
    }
    
    public init(position: vec4, texCoord1: vec2, texCoord2: vec2, color: vec4) {
        self.position  = position
        self.texCoord1 = texCoord1
        self.texCoord2 = texCoord2
        self.color     = color
    }
    
    public func transformed(_ m: Matrix4x4f) -> RendererVertex {
        return RendererVertex(position: m * position, texCoord1: texCoord1, texCoord2: texCoord2, color: color)
    }
}
