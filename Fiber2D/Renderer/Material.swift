//
//  Material.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 24.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath
import SwiftBGFX

public final class Material {
    public var technique: Technique
    
    public init(technique: Technique) {
        self.technique = technique
    }
    
    // Global uniform handle cache
    internal static var handles = [String: Uniform]()
    
    internal var vec4Uniforms       = [Uniform: Vector4f]()
    internal var mat4Uniforms       = [Uniform: Matrix4x4f]()
    internal var vec4BufferUniforms = [Uniform: [Vector4f]]()
    internal var mat4BufferUniforms = [Uniform: [Matrix4x4f]]()
    internal var textureUniforms    = [Uniform: (unit: UInt8, texture: Texture)]()
    
    public func set(uniform: [Vector4f], name: String) {
        let handle = Material.handle(for: name, type: .vector4, num: uniform.count)
        vec4BufferUniforms[handle] = uniform
    }
    
    public func set(uniform: [Matrix4x4f], name: String) {
        let handle = Material.handle(for: name, type: .matrix4x4, num: uniform.count)
        mat4BufferUniforms[handle] = uniform
    }
    
    public func set(uniform: Vector4f, name: String) {
        let handle = Material.handle(for: name, type: .vector4)
        vec4Uniforms[handle] = uniform
    }
    
    public func set(uniform: Matrix4x4f, name: String) {
        let handle = Material.handle(for: name, type: .matrix4x4)
        mat4Uniforms[handle] = uniform
    }
    
    public func set(texture: Texture?, unit: UInt8, name: String) {
        let handle = Material.handle(for: name, type: .int1)
        if let texture = texture {
            textureUniforms[handle] = (unit: unit, texture: texture)
        } else {
            textureUniforms[handle] = nil
        }
    }
}

internal extension Material {
    static func handle(for name: String, type: UniformType, num: Int = 1) -> Uniform {
        guard num > 0 else {
            fatalError("Uniform handle must be at least 1 element long")
        }
        
        let key = name + "_" + String(type.rawValue) + "_" + String(num)
        if let handle = Material.handles[key] {
            return handle
        }
        
        let newHandle = Uniform(name: name, type: type, num: UInt16(num))
        Material.handles[key] = newHandle
        return newHandle
    }
}

internal extension Material {
    internal func apply() {
        if vec4Uniforms.count > 0 {
            for (key, value) in vec4Uniforms {
                bgfx.setUniform(key, value: value)
            }
        }
        
        if mat4Uniforms.count > 0 {
            for (key, value) in mat4Uniforms {
                bgfx.setUniform(key, value: value)
            }
        }
        
        // vec4/mat4 arrays and mat3 supports have to be done in SwiftBGFX
        
        if textureUniforms.count > 0 {
            for (key, value) in textureUniforms {
                bgfx.setTexture(value.unit, sampler: key, texture: value.texture.texture)
            }
        }
    }
}

extension Material: Cloneable {
    public var clone: Material {
        return Material(technique: technique)
    }
}
