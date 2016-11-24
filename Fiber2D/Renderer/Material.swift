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
    
    // Global uniform handle cache
    internal static var handles = [String: Uniform]()
    
    internal var vec4Uniforms       = [Uniform: Vector4f]()
    internal var mat4Uniforms       = [Uniform: Matrix4x4f]()
    internal var vec4BufferUniforms = [Uniform: [Vector4f]]()
    internal var mat4BufferUniforms = [Uniform: [Matrix4x4f]]()
    internal var textureUniforms    = [Uniform: (unit: UInt8, texture: Texture)]()
    
    public var blendMode: BlendMode = .premultipliedAlphaMode {
        didSet {
            if blendMode != oldValue {
                renderStateDirty = true
            }
        }
    }
    
    /// Cache and return the current render state.
    internal(set) public var renderState: RenderStateOptions {
        get {
            if renderStateDirty {
                _renderState = .colorWrite | .alphaWrite | .multisampling | blendMode.state | blendMode.equation
                renderStateDirty = false
            }
            return _renderState
        }
        set { _renderState = newValue }
    }
    
    internal var renderStateDirty = true
    
    private var _renderState: RenderStateOptions = .default
    
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
    
    public func set(texture: Texture, unit: UInt8, name: String) {
        let handle = Material.handle(for: name, type: .int1)
        textureUniforms[handle] = (unit: unit, texture: texture)
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
