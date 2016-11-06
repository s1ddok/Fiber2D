//
//  BGFXRenderer+RenderTexture.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 05.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftBGFX

// Ugly sketch, but should work
// Will not handle nested RTTs, I think
internal extension BGFXRenderer {
    internal func beginRenderTexture(_ rt: RenderTexture) {
        // Push current view ID
        viewStack.append(currentViewID)
        
        currentViewID = currentRenderTargetViewID
        
        bgfx.setViewSequential(viewId: currentViewID, enabled: true)
        bgfx.setViewRect(viewId: currentViewID, x: 0, y: 0,
                         width: UInt16(rt.contentSize.width), height: UInt16(rt.contentSize.height))
        bgfx.setViewFrameBuffer(viewId: currentViewID, buffer: rt.framebuffer!)
        bgfx.setViewClear(viewId: currentViewID, options: [.color, .discardDepth, .discardStencil], rgba: 0x30_00_00_ff, depth: 0.0, stencil: 0)
        bgfx.touch(currentViewID)
        
        bgfx.setViewTransform(viewId: currentViewID, proj: rt.projection)
    }
    
    internal func endRenderTexture() {
        // Pop current view ID
        currentViewID = viewStack.removeLast()
        
        currentRenderTargetViewID += 1
    }
}
