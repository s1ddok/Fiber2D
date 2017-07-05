//
//  Director+RunLoop.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 15.12.16.
//
//

public extension Director {
    
    /**
     Start the main run loop of the game, drawing and updating.
     Generally, as a user, you will start the main loop by running a scene, using `presentScene`
     @see stopRunLoop
     */
    public func startRunLoop() {
        nextDeltaTimeZero = true
        isAnimating = true
    }
    
    /**
     Stops the run loop. Nothing will be drawn or simulated. The main loop won't be triggered anymore.
     If you want to pause your game call [pause] instead.
     */
    public func stopRunLoop() {
        isAnimating = false
    }
    
    /** Run the main loop once, handle updates and draw scene
     This method is called every frame. Don't call it manually.
     */
    public func mainLoopBody() {
        guard isAnimating else {
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
        /* to avoid flickr, nextScene MUST be here: after tick and before draw. */
        if nextScene != nil {
            self.setNextScene()
        }
        view!.beginFrame()
        let projection = runningScene.projection
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
            // TODO: Completion handlers here
        }
        renderer.flush()
        totalFrames += 1
        Director.popCurrentDirector()
    }

}
