//
//  Pass.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 24.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftBGFX

// Considerations:
// 1. Maybe implement this as a struct?
// 2. Should we allows modification of the properies?
// 3. Should this be cached?

// TODO: 
// 1. Data-driven load from XML/JSON/YAML

/// Material rendering pass, which defines shaders and render state.
public final class Pass {
    internal(set) public var fragmentShader: Shader
    internal(set) public var vertexShader:   Shader
    internal var program: Program
    
    internal(set) public var blendMode: BlendMode {
        didSet {
            if blendMode != oldValue {
                renderStateDirty = true
            }
        }
    }

    public var cullMode: CullMode = .none
    
    /// Control multisampling
    internal(set) public var multisampling: Bool
    
    /// Control depth writing
    internal(set) public var depthWrite: Bool
    
    /// Cache and return the current render state.
    internal(set) public var renderState: RenderStateOptions {
        get {
            if renderStateDirty {
                _renderState = Pass.defaultRenderState | blendMode.state | blendMode.equation | cullMode.renderState
                
                if depthWrite {
                    _renderState = _renderState.union(.depthWrite)
                }
                
                if multisampling {
                    _renderState = _renderState.union(.multisampling)
                }
                renderStateDirty = false
            }
            return _renderState
        }
        set { _renderState = newValue }
    }
    
    internal var renderStateDirty = true
    private var _renderState: RenderStateOptions = .default
    internal static let defaultRenderState: RenderStateOptions = .colorWrite | .alphaWrite
    
    public init(vertexShader: Shader,
                fragmentShader: Shader,
                blendMode: BlendMode = .premultipliedAlphaMode,
                depthWrite: Bool = false,
                multisampling: Bool = true) {
        self.vertexShader = vertexShader
        self.fragmentShader = fragmentShader
        self.program = Program(vertex: vertexShader, fragment: fragmentShader)
        self.blendMode = blendMode
        self.depthWrite = depthWrite
        self.multisampling = multisampling
    }
}

extension Pass: Hashable {
    public var hashValue: Int {
        return Int(renderState.rawValue) + fragmentShader.hashValue + vertexShader.hashValue
    }
    
    public static func ==(lhs: Pass, rhs: Pass) -> Bool {
        return lhs.renderState    == rhs.renderState &&
               lhs.fragmentShader == rhs.fragmentShader &&
               lhs.vertexShader   == rhs.vertexShader
    }
}

extension Pass {
    public static let positionColor: Pass = {
        let vs = Shader(source: vs_shader, language: .metal, type: .vertex)
        let fs = Shader(source: fs_shader, language: .metal, type: .fragment)
        return Pass(vertexShader: vs, fragmentShader: fs)
    }()
    
    public static let positionTexture: Pass = {
        let vs = Shader(source: vs_shader, language: .metal, type: .vertex)
        let fs = Shader(source: fs_texture_shader, language: .metal, type: .fragment)
        return Pass(vertexShader: vs, fragmentShader: fs)
    }()
}
