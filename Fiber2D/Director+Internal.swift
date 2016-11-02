//
//  Director+Internal.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 29.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath
import Quartz

/**
 Get the current time in seconds.
 */
internal extension Time {
    internal static var absoluteTime: Time {
        #if os(iOS) || os(tvOS) || os(OSX) || os(watchOS)
            return Time(CACurrentMediaTime())
        #endif
    }
}

internal extension Director {
    /// Add a block to be called when the GPU finishes rendering a frame.
    /// This is used to pool rendering resources (renderers, buffers, textures, etc) without stalling the GPU pipeline.
    internal func add(frameCompletionHandler: @escaping ()->()) {
        self.view!.add(frameCompletionHandler: frameCompletionHandler)
    }
    
    /**
     Start the main run loop of the game, drawing and updating.
     Generally, as a user, you will start the main loop by running a scene, using `presentScene`
     @see stopRunLoop
     */
    internal func startRunLoop() {
        self.nextDeltaTimeZero = true
    }
    
    /**
     Stops the run loop. Nothing will be drawn or simulated. The main loop won't be triggered anymore.
     If you want to pause your game call [pause] instead.
     */
    internal func stopRunLoop() {
        print("Director#stopRunLoop. Override me")
    }
    
    internal func mainLoopBody() {
        if !animating {
            return
        }
        Director.pushCurrentDirector(self)
        /* calculate "global" dt */
        calculateDeltaTime()
        /* tick before glClear: issue #533 */
        guard let runningScene = runningScene else {
            return
        }
        
        if !isPaused {
            runningScene.scheduler.update(dt)
        }
        /* to avoid flickr, nextScene MUST be here: after tick and before draw.
         XXX: Which bug is this one. It seems that it can't be reproduced with v0.9 */
        if nextScene != nil {
            self.setNextScene()
        }
        view!.beginFrame()
        let projection = runningScene.projection
        // Synchronize the framebuffer with the view.
        let renderer: Renderer = self.rendererFromPool()
        
        renderer.prepare(withProjection: projection)
        
        //CCRenderer.bindRenderer(renderer)
        currentRenderer = renderer
        renderer.enqueueClear(color: runningScene.colorRGBA)
        // Render
        runningScene.visit(renderer, parentTransform: projection)
        notificationNode?.visit(renderer, parentTransform: projection)
        
        //CCRenderer.bindRenderer(nil)
        currentRenderer = nil
        view!.add {
            // Return the renderer to the pool when the frame completes.
            self.poolRenderer(renderer)
        }
        renderer.flush()
        view!.presentFrame()
        totalFrames += 1
        Director.popCurrentDirector()
    }
    
    /// Rect of the visible screen area in GL coordinates.
    internal var viewportRect: Rect {
        var projection = runningScene!.projection
        // TODO It's _possible_ that a user will use a non-axis aligned projection. Weird, but possible.
        let projectionInv = projection.inversed
        // Calculate z=0 using -> transform*[0, 0, 0, 1]/w
        let zClip = projection[3, 2] / projection[3, 3]
        // Bottom left and top right coords of viewport in clip coords.
        let clipBL = Vector3f(-1.0, -1.0, zClip)
        let clipTR = Vector3f(1.0, 1.0, zClip)
        // Bottom left and top right coords in GL coords.
        let glBL = projectionInv.multiplyAndProject(v: clipBL).xy
        let glTR = projectionInv.multiplyAndProject(v: clipTR).xy
        return Rect(bottomLeft: glBL, topRight: glTR)
    }
    
    /// Get a renderer object to use for rendering.
    internal func rendererFromPool() -> Renderer {
        if r == nil {
            r = BGFXRenderer()
        }
        /*let lockQueue = dispatch_queue_create("com.test.LockQueue")
         dispatch_sync(lockQueue) {
         if rendererPool.count > 0 {
         var renderer: CCRenderer = rendererPool.lastObject
         rendererPool.removeLastObject()
         return renderer
         }
         }*/
        // Allocate and return a new renderer.
        //return CCRendererImpl(renderer: CCRenderer())
        return r!
    }
    
    /// Return a renderer to a pool after rendering.
    internal func poolRenderer(_ renderer: Renderer) {
        /*let lockQueue = dispatch_queue_create("com.test.LockQueue")
         dispatch_sync(lockQueue) {
         rendererPool.append(renderer)
         }*/
    }
}
