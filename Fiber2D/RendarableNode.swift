//
//  RendarableNode.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftBGFX

open class RenderableNode: Node {
    var shader: Program {
        didSet {
            //render state dirty
            renderStateDirty = true
        }
    }
    private(set) var shaderUniforms: [String : Any]! {
        get {
            if _shaderUniforms == nil {
                _shaderUniforms = [ShaderUniformMainTexture : texture]
            }
            
            return _shaderUniforms
        }
        set {
            _shaderUniforms = newValue
        }
    }
    private var _shaderUniforms: [String: Any]?
    
    
    public var blendMode: BlendMode {
        didSet {
            if blendMode != oldValue {
                renderStateDirty = true
            }
        }
    }
    
    public var texture: Texture! {
        didSet {
            if texture !== oldValue {
                // Set the main texture in the uniforms dictionary (if the dictionary exists).
                shaderUniforms?[ShaderUniformMainTexture] = texture
            }
        }
    }
    
    public var secondaryTexture: Texture? {
        didSet {
            if secondaryTexture !== oldValue {
                // Set the main texture in the uniforms dictionary (if the dictionary exists).
                shaderUniforms?[ShaderUniformSecondaryTexture] = secondaryTexture
            }
        }
    }

    /// Cache and return the current render state.
    internal(set) public var renderState: RenderStateOptions {
        get {
            if renderStateDirty {
                _renderState = .colorWrite | .alphaWrite | .multisampling | blendMode.state | blendMode.equation
                _renderState.remove(.depthWrite)
                renderStateDirty = false
            }
            return _renderState
        }
        set {
            _renderState = newValue
        }
    }
    
    internal var renderStateDirty = true
    
    private var _renderState: RenderStateOptions = .default
    
    override init() {
        shader = .posColor
        blendMode = .premultipliedAlphaMode
        
        super.init()
    }
    
    var usesCustomShaderUniforms: Bool {
        /*let texture: CCTexture = self.texture ?? CCTexture.none()
        if CheckDefaultUniforms(shaderUniforms, texture: texture) {
            // If the uniform dictionary was set, it was the default. Throw it away.
            self.shaderUniforms = nil
            return false
        }
        
        return true*/
        return false
    }
    
    /*private func CheckDefaultUniforms(_ uniforms: [String: Any]?, texture: CCTexture) -> Bool
    {
        guard uniforms != nil else {
            return true
        }
        // Check that the uniforms has only one key for the main texture.
        return uniforms!.count == 1 && uniforms![ShaderUniformMainTexture] as! CCTexture == texture
    }*/
}
