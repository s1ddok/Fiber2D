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
        
        if currentTree == nil {
            // Means this is a top-level tree
            currentTree = Tree(value: currentRenderTargetViewID)
            rtTrees.append(currentTree!)
        } else {
            // Means we are creating +1 level of nested RTs
            // Create new entry
            let newTree = Tree(value: currentRenderTargetViewID)
            
            // put that as a child of current tree
            currentTree!.add(child: newTree)
            // Make that new tree a new current one
            currentTree = newTree
            
            // Assign every time
            currentFrameHasNestedRTS = true
        }
        
        bgfx.set(viewMode: .sequental, for: currentViewID)
        
        let rtPixelSize = rt.pixelSize
        bgfx.setViewRect(viewId: currentViewID, x: 0, y: 0,
                         width: UInt16(rtPixelSize.width), height: UInt16(rtPixelSize.height))
        bgfx.setViewFrameBuffer(viewId: currentViewID, buffer: rt.framebuffer!)
        bgfx.setViewClear(viewId: currentViewID, options: [.color], rgba: rt.clearColor.uint32Representation, depth: 1.0, stencil: 0)
        bgfx.touch(currentViewID)
        
        bgfx.setViewTransform(viewId: currentViewID, proj: rt.projection)
        
        currentRenderTargetViewID += 1
    }
    
    internal func endRenderTexture() {
        // Pop current view ID
        currentViewID = viewStack.removeLast()
        if currentTree == nil {
            fatalError("Can't pop RTs group as we don't have none")
        }
        currentTree = currentTree!.parent
    }
}
