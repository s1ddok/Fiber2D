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
            renderState = nil
        }
    }
    private(set) var shaderUniforms: [String : Any]! {
        get {
            if _shaderUniforms == nil {
                _shaderUniforms = [ShaderUniformMainTexture : texture ?? CCTexture.none()]
            }
            
            return _shaderUniforms
        }
        set {
            _shaderUniforms = newValue
        }
    }
    private var _shaderUniforms: [String: Any]?
    
    
    var blendMode: CCBlendMode {
        didSet {
            if blendMode != oldValue {
                renderState = nil
            }
        }
    }
    var texture: CCTexture! {
        didSet {
            if texture != oldValue {
                renderState = nil
                // Set the main texture in the uniforms dictionary (if the dictionary exists).
                shaderUniforms?[ShaderUniformMainTexture] = texture ?? CCTexture.none()
            }
        }
    }
    var secondaryTexture: CCTexture? {
        didSet {
            if texture != oldValue {
                renderState = nil
                // Set the main texture in the uniforms dictionary (if the dictionary exists).
                shaderUniforms?[ShaderUniformSecondaryTexture] = texture ?? CCTexture.none()
            }
        }
    }

    /// Cache and return the current render state.
    /// Should be set to nil whenever changing a property that affects the renderstate.
    var renderState: CCRenderState! {
        get {
            if _renderState == nil {
                let texture: CCTexture = self.texture ?? CCTexture.none()
                if CheckDefaultUniforms(shaderUniforms, texture: texture) {
                    // Create a cached render state so we can use the fast path.
                    //self._renderState = CCRenderState(blendMode: blendMode, shader: shader, mainTexture: texture)
                    // If the uniform dictionary was set, it was the default. Throw it away.
                    self.shaderUniforms = nil
                } else {
                    // Since the node has unique uniforms, it cannot be batched or use the fast path.
                    //self._renderState = CCRenderState(blendMode: blendMode, shader: shader, shaderUniforms: shaderUniforms, copyUniforms: false)
                }
            }
            return _renderState
        }
        set {
            _renderState = newValue
        }
    }
    
    private var _renderState: CCRenderState? = nil
    
    override init() {
        shader = .posColor
        blendMode = CCBlendMode.premultipliedAlpha()
        
        super.init()
    }
    
    var usesCustomShaderUniforms: Bool {
        let texture: CCTexture = self.texture ?? CCTexture.none()
        if CheckDefaultUniforms(shaderUniforms, texture: texture) {
            // If the uniform dictionary was set, it was the default. Throw it away.
            self.shaderUniforms = nil
            return false
        }
        
        return true
    }
    
    private func CheckDefaultUniforms(_ uniforms: [String: Any]?, texture: CCTexture) -> Bool
    {
        guard uniforms != nil else {
            return true
        }
        // Check that the uniforms has only one key for the main texture.
        return uniforms!.count == 1 && uniforms![ShaderUniformMainTexture] as! CCTexture == texture
    }
}
