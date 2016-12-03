//
//  Geometry.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 03.12.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath
import SwiftBGFX

public struct Geometry {
    public var vertexBuffer: [RendererVertex]
    public var indexBuffer:  [UInt16]
    
    public var positions: [Vector4f] {
        get {
            return vertexBuffer.map { $0.position }
        }
        set {
            if newValue.count != vertexBuffer.count {
                print("WARNING: Position buffer sized differently from vertex buffer.")
            }
            
            for i in 0..<min(vertexBuffer.count, newValue.count) {
                vertexBuffer[i].position = newValue[i]
            }
        }
    }
    
    public var uv: [Vector2f] {
        get {
            return vertexBuffer.map { $0.texCoord1 }
        }
        set {
            if newValue.count != vertexBuffer.count {
                print("WARNING: UV buffer sized differently from vertex buffer.")
            }
            
            for i in 0..<min(vertexBuffer.count, newValue.count) {
                vertexBuffer[i].texCoord1 = newValue[i]
            }
        }
    }
    
    public var uv2: [Vector2f] {
        get {
            return vertexBuffer.map { $0.texCoord2 }
        }
        set {
            if newValue.count != vertexBuffer.count {
                print("WARNING: UV2 buffer sized differently from vertex buffer.")
            }
            
            for i in 0..<min(vertexBuffer.count, newValue.count) {
                vertexBuffer[i].texCoord2 = newValue[i]
            }
        }
    }
    
    public var color: Color {
        get {
            if vertexBuffer.count > 0 {
                return vertexBuffer.first!.color
            }
            
            return .zero
        }
        set {
            for i in 0..<vertexBuffer.count {
                vertexBuffer[i].color = newValue
            }
        }
    }
    
    public var colors: [Color] {
        get {
            return vertexBuffer.map { $0.color }
        }
        set {
            if newValue.count != vertexBuffer.count {
                print("WARNING: Color buffer sized differently from vertex buffer.")
            }
            
            for i in 0..<min(vertexBuffer.count, newValue.count) {
                vertexBuffer[i].color = newValue[i]
            }
        }
    }
}
