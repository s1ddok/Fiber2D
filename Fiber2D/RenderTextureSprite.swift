//
//  RenderTextureSprite.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation

class RenderTextureSprite: Sprite {
    weak var renderTexture: RenderTexture?
    
    override var renderState: CCRenderState! {
        get {
            if super.renderState == nil {
                // Allowing the uniforms to be copied speeds up the rendering by making the render state immutable.
                // Copy the uniforms if custom uniforms are not being used.
                let copyUniforms: Bool = !self.usesCustomShaderUniforms
                // Create an uncached renderstate so the texture can be released before the renderstate cache is flushed.
                self.renderState = CCRenderState(blendMode: blendMode, shader: shader, shaderUniforms: self.shaderUniforms as [NSObject: AnyObject], copyUniforms: copyUniforms)
            }
            return super.renderState
        }
        set {
            super.renderState = newValue
        }
    }
    
    var nodeToWorldTransform: Matrix4x4f {
        var t = self.nodeToParentMatrix
        var p: Node? = renderTexture
        while p != nil {
            t = p!.nodeToParentMatrix * t
            p = p!.parent
        }
        return t
    }
}
