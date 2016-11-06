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
        
        let rtPixelSize = rt.pixelSize
        bgfx.setViewRect(viewId: currentViewID, x: 0, y: 0,
                         width: UInt16(rtPixelSize.width), height: UInt16(rtPixelSize.height))
        bgfx.setViewFrameBuffer(viewId: currentViewID, buffer: rt.framebuffer!)
        bgfx.setViewClear(viewId: currentViewID, options: [.color], rgba: rt.clearColor.uint32Representation, depth: 1.0, stencil: 0)
        bgfx.touch(currentViewID)
        
        bgfx.setViewTransform(viewId: currentViewID, proj: rt.projection)
    }
    
    internal func endRenderTexture() {
        // Pop current view ID
        currentViewID = viewStack.removeLast()
        
        currentRenderTargetViewID += 1
    }
}
