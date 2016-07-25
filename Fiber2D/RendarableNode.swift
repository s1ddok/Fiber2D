//
//  RendarableNode.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation

class RenderableNode: Node {
    var shader: CCShader {
        didSet {
            //render state dirty
            renderState = nil
        }
    }
    private(set) var shaderUniforms: [NSObject : AnyObject]! {
        get {
            if _shaderUniforms == nil {
                _shaderUniforms = [CCShaderUniformMainTexture : texture ?? CCTexture.none()]
            }
            
            return _shaderUniforms
        }
        set {
            _shaderUniforms = newValue
        }
    }
    private var _shaderUniforms: [NSObject: AnyObject]?
    
    
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
                shaderUniforms?[CCShaderUniformMainTexture] = texture ?? CCTexture.none()
            }
        }
    }
    var secondaryTexture: CCTexture? {
        didSet {
            if texture != oldValue {
                renderState = nil
                // Set the main texture in the uniforms dictionary (if the dictionary exists).
                shaderUniforms?[CCShaderUniformSecondaryTexture] = texture ?? CCTexture.none()
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
                    self._renderState = CCRenderState(blendMode: blendMode, shader: shader, mainTexture: texture)
                    // If the uniform dictionary was set, it was the default. Throw it away.
                    self.shaderUniforms = nil
                } else {
                    // Since the node has unique uniforms, it cannot be batched or use the fast path.
                    self._renderState = CCRenderState(blendMode: blendMode, shader: shader, shaderUniforms: shaderUniforms, copyUniforms: false)
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
        shader = CCShader.positionColorShader()
        blendMode = CCBlendMode.premultipliedAlphaMode()
        
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
    
    private func CheckDefaultUniforms(uniforms: [NSObject: AnyObject]?, texture: CCTexture) -> Bool
    {
        guard uniforms != nil else {
            return true
        }
        // Check that the uniforms has only one key for the main texture.
        return uniforms!.count == 1 && uniforms![CCShaderUniformMainTexture] as! CCTexture == texture
    }
}