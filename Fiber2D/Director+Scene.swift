//
//  Director+Scene.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 10.12.16.
//
//

public extension Director {
    
    /**
     *  Presents a new scene.
     *
     *  If no scene is currently running, the scene will be started.
     *
     *  If another scene is currently running, this scene will be stopped, and the new scene started.
     *
     *  @param scene Scene to start.
     *  @see Director.present(scene:withTransition:)
     */
    public func present(scene: Scene) {
        if runningScene != nil {
            self.sendCleanupToScene = true
            scenesStack.removeLastObject()
            scenesStack.add(scene)
            self.nextScene = scene
            // _nextScene is a weak ref
        } else {
            self.run(with: scene)
        }
    }
    
    /**
     *  Presents a new scene, with a transition.
     *
     *  If no scene is currently running, the new scene will be started without a transition.
     *
     *  If another scene is currently running, this scene will be stopped, and the new scene started, according to the provided transition.
     *
     *  @param scene Scene to start.
     *  @param transition Transition to use. Can be nil.
     *  @see Director.present(scene:)
     */
    public func present(scene: Scene, withTransition transition: Transition) {
        if runningScene != nil {
            self.sendCleanupToScene = true
            // the transition gets to become the running scene
            transition.startTransition(scene, withDirector: self)
        } else {
            self.run(with: scene)
        }
    }
    
    //
    // MARK: Scene stack
    //
    
    /**
     * Suspends the execution of the running scene, pushing it on the stack of suspended scenes.
     *
     * The new scene will be executed, the previous scene remains in memory.
     * Try to avoid big stacks of pushed scenes to reduce memory allocation.
     *
     *  @warning ONLY call it if there is already a running scene.
     *
     *  @param scene New scene to start.
     *  @see Director.push(scene:withTransition:)
     *  @see Director.popScene
     *  @see Director.popToRootScene
     */
    public func push(scene: Scene) {
        self.sendCleanupToScene = false
        scenesStack.add(scene)
        self.nextScene = scene
        // _nextScene is a weak ref
    }
    
    /**
     *  Pushes the running scene onto the scene stack, and presents the incoming scene, using a transition
     *
     *  @param scene      The scene to present
     *  @param transition The transition to use
     *  @see Director.push(scene:)
     */
    public func push(scene: Scene, withTransition transition: Transition) {
        scenesStack.add(scene)
        self.sendCleanupToScene = false
        transition.startTransition(scene, withDirector: self)
    }
    
    /** Pops out a scene from the queue. This scene will replace the running one.
     * The running scene will be deleted. If there are no more scenes in the stack the execution is terminated.
     *
     *  @warning ONLY call it if there is a running scene.
     *
     *  @see Director.pushScene
     *  @see Director.popScene(with:)
     *  @see Director.popToRootScene
     */
    public func popScene() {
        assert(runningScene != nil, "A running Scene is needed")
        scenesStack.removeLastObject()
        let c: Int = scenesStack.count
        if c == 0 {
            self.end()
        } else {
            self.sendCleanupToScene = true
            self.nextScene = scenesStack[c - 1] as? Scene
        }
    }
    
    /**
     *  Replaces the running scene, with the last scene pushed to the stack, using a transition
     *
     *  @param transition The transition to use
     *	@see popScene
     */
    public func popScene(with transition: Transition) {
        assert(runningScene != nil, "A running Scene is needed")
        if scenesStack.count < 2 {
            self.end()
        } else {
            scenesStack.removeLastObject()
            let incomingScene = scenesStack.lastObject as! Scene
            self.sendCleanupToScene = true
            transition.startTransition(incomingScene, withDirector: self)
        }
    }
    
    /** Pops out all scenes from the queue until the root scene in the queue.
     *
     * This scene will replace the running one.
     * Internally it will call `popToSceneStackLevel:1`
     *  @see Director.popScene
     *  @see Director.push(scene:)
     */
    public func popToRootScene() {
        self.pop(to: 1)
    }
    
    /** Pops out all scenes from the queue until the root scene in the queue, using a transition
     *
     * This scene will replace the running one. Internally it will call `popToRootScene`
     * @param transition The transition to play.
     *  @see Director.popToRootScene
     */
    public func popToRootScene(with transition: Transition) {
        self.popToRootScene()
        self.sendCleanupToScene = true
        transition.startTransition(nextScene!, withDirector: self)
    }
    
    /** Pops out all scenes from the queue until it reaches `level`.
     If level is 0, it will end the director.
     If level is 1, it will pop all scenes until it reaches to root scene.
     If level is <= than the current stack level, it won't do anything.
     */
    public func pop(to level: Int) {
        assert(runningScene != nil, "A running Scene is needed")
        var c: Int = scenesStack.count
        // level 0? -> end
        if level == 0 {
            self.end()
            return
        }
        // current level or lower -> nothing
        if level >= c {
            return
        }
        // pop stack until reaching desired level
        while c > level {
            let current = scenesStack.lastObject as! Scene
            if current.active {
                current._onExitTransitionDidStart()
                current._onExit()
            }
            current.cleanup()
            scenesStack.removeLastObject()
            c -= 1
        }
        self.nextScene = scenesStack.lastObject as? Scene
        self.sendCleanupToScene = false
    }
    
}

//
// MARK: Internal
//

internal extension Director {
    
    internal func run(with scene: Scene) {
        assert(runningScene == nil, "This command can only be used to start the Director. There is already a scene present.")
        self.push(scene: scene)
        scene.director = self
        self.antiFlickrDrawCall()
        self.setNextScene()
        self.startRunLoop()
    }
    
    internal func start(transition: Transition) {
        assert(runningScene != nil, "There must be a running scene")
        scenesStack.removeLastObject()
        scenesStack.add(transition)
        self.nextScene = transition
    }
    
    internal func setNextScene() {
        // If next scene is a transition, the transition has just started
        // Make transition the running scene.
        // Outgoing scene will continue to run
        // Incoming scene was started by transition
        if (nextScene is Transition) {
            self.runningScene = nil
            self.nextScene!.director = self
            self.runningScene = nextScene
            self.nextScene = nil
            runningScene!._onEnter()
            responderManager.markAsDirty()
            return
        }
        // If running scene is a transition class, the transition has ended
        // Make new scene, the running scene
        // Clean up transition
        // Outgoing scene was stopped by transition
        if (runningScene is Transition) {
            runningScene!._onExit()
            runningScene!.cleanup()
            self.runningScene!.director = nil
            self.runningScene = nil
            self.runningScene = nextScene
            self.nextScene = nil
            return
        }
        // if next scene is not a transition, force exit calls
        if !(nextScene is Transition) {
            runningScene?._onExitTransitionDidStart()
            runningScene?._onExit()
            // issue #709. the root node (scene) should receive the cleanup message too
            // otherwise it might be leaked.
            if sendCleanupToScene {
                runningScene!.cleanup()
            }
        }
        self.runningScene = nextScene
        self.nextScene = nil
        // if running scene is not a transition, force enter calls
        if !(runningScene is Transition) {
            runningScene!._onEnter()
            runningScene!._onEnterTransitionDidFinish()
            responderManager.markAsDirty()
            runningScene!.paused = false
        }
    }
    
}
