//
//  Director.swift
//
//  Created by Andrey Volodin on 08.06.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation
import MetalKit
import SwiftMath

let DirectorCurrentKey = "DirectorCurrentKey"
let DirectorStackKey   = "DirectorStackKey"

func DirectorBindCurrent(_ director: AnyObject?) {
    if director != nil || !(director is NSNull) {
        Thread.current.threadDictionary[DirectorCurrentKey] = director
    } else {
        Thread.current.threadDictionary.removeObject(forKey: DirectorCurrentKey)
    }
}

func DirectorStack() -> NSMutableArray
{
    var stack = Thread.current.threadDictionary[DirectorStackKey] as? NSMutableArray
    if stack == nil {
        stack = NSMutableArray()
        Thread.current.threadDictionary[DirectorStackKey] = stack
    }
    return stack!
}

public class Director: NSObject {
    class var currentDirector: Director? {
        return Thread.current.threadDictionary[DirectorCurrentKey] as? Director
    }
    
    class func pushCurrentDirector(_ director: Director) {
        let stack = DirectorStack()
        stack.add(self.currentDirector ?? NSNull())
        DirectorBindCurrent(director)
    }
    
    class func popCurrentDirector() {
        let stack = DirectorStack()
        assert(stack.count > 0, "Director stack underflow.")
        DirectorBindCurrent(stack.lastObject as AnyObject?)
        stack.removeLastObject()
    }
    
    // internal timer
    var oldFrameSkipInterval: Int = 1
    var frameSkipInterval: Int = 1
    /* stats */
    var displayStats: Bool
    var frames: Int
    var totalFrames: Int
    var secondsPerFrame: Time = 0.0
    var accumDt: Time = 0.0
    var frameRate: Time = 0.0
    /* is the running scene paused */
    var isPaused: Bool = false
    /* Is the director running */
    var animating: Bool = false
    /* The running scene */
    var runningScene: Scene?
    /* This object will be visited after the scene. Useful to hook a notification node */
    var notificationNode: Node?
    /* will be the next 'runningScene' in the next frame
     nextScene is a weak reference. */
    internal weak var nextScene: Scene?
    
    /* Whether or not the replaced scene will receive the cleanup message.
     If the new scene is pushed, then the old scene won't receive the "cleanup" message.
     If the new scene replaces the old one, the it will receive the "cleanup" message.
     */
    /* If YES, then "old" scene will receive the cleanup message */
    internal var sendCleanupToScene: Bool = false
    /* scheduled scenes */
    var scenesStack = NSMutableArray()
    /* last time the main loop was updated */
    var lastUpdate: Time = 0.0
    /* delta time since last tick to main loop */
    var dt: Time = 0.0
    /* whether or not the next delta time will be zero */
    var nextDeltaTimeZero: Bool = false
    //var rendererPool: [AnyObject]
    
    // Undocumented members (considered private)
    var responderManager: ResponderManager!
    
    /// User definable value that is used for default contentSizes of many node types (Scene, NodeColor, etc).
    /// Defaults to the view size.
    var designSize : Size {
        get {
            // Return the viewSize unless designSize has been set.
            return (_designSize == Size.zero ? self.viewSize : _designSize)
        }
        
        set {
            _designSize = newValue
        }
    }
    private var _designSize = Size.zero
    /** @name Working with View and Projection */
    /// View used by the director for rendering.
    weak var view: DirectorView?
    
    /// The current global shader values values.
	var globalShaderUniforms = [String: AnyObject]()
    
    init(view: DirectorView) {
        self.displayStats = false
        self.totalFrames = 0
        self.frames = 0
        self.isPaused = false
        super.init()
        self.view = view
        // scenes
        //self.scenesStack = [Scene]()
        //self.delegate = nil
        // FPS

        self.responderManager = ResponderManager(director: self)
        //self.rendererPool = NSMutableArray()
        self.globalShaderUniforms = Dictionary()
    }
    
    /*func description() -> String {
        var size: Size = self.viewSize
        return "<\(self.self) = \(self) | Size: %0.f x %0.f, view = \(size.width)>"
    }*/
    
    func run() {
        DispatchQueue.global(qos: .userInteractive).async {
            
        }
    }
    
    var r: Renderer?
    
    func calculateDeltaTime() {
        let now = Time.absoluteTime
        // new delta time
        if nextDeltaTimeZero {
            self.dt = 0
            self.nextDeltaTimeZero = false
        }
        else {
            self.dt = now - lastUpdate
            self.dt = max(0, dt)
        }
        // If we are debugging our code, prevent big delta time
        if dt > 0.2 {
            self.dt = 1 / 60.0
        }
        self.lastUpdate = now
    }
    
    func purgeCachedData() {
        if Director.currentDirector?.view != nil {
            TextureCache.shared.removeUnusedTextures()
        }
        FileLocator.shared.purgeCache()
    }
    
    var flipY: Float {
        #if os(iOS)
        return -1.0
        #endif
        #if os(OSX)
        return 1.0
        #endif
    }
    
    func convertToGL(_ uiPoint: Point) -> Point {
        var transform = runningScene!.projection
        let invTransform = transform.inversed
        // Calculate z=0 using -> transform*[0, 0, 0, 1]/w
        let zClip: Float = transform[3, 2] / transform[3, 3]
        let glSize: Size = viewSize
        var clipCoord = vec3(2.0 * Float(uiPoint.x / glSize.width) - 1.0, 2.0 * Float(uiPoint.y / glSize.height) - 1.0, zClip)
        clipCoord.y *= flipY
        return invTransform.multiplyAndProject(v: clipCoord).xy
    }
    
    func convertToUI(_ glPoint: Point) -> Point {
        let transform = runningScene!.projection
        let clipCoord = transform.multiplyAndProject(v: vec3(glPoint))
        let glSize: Size = viewSize
        return glSize * p2d(clipCoord.x * 0.5 + 0.5, clipCoord.y * flipY * 0.5 + 0.5)
    }
    
    var viewSize: Size {
        return view!.size
    }
    
    var viewSizeInPixels: Size {
        return view!.sizeInPixels
    }
    
    func antiFlickrDrawCall() {
        // Questionable "anti-flickr", extra draw call:
        // overridden for android.
        self.mainLoopBody()
    }
    
    func present(scene: Scene) {
        if runningScene != nil {
            self.sendCleanupToScene = true
            scenesStack.removeLastObject()
            scenesStack.add(scene)
            self.nextScene = scene
            // _nextScene is a weak ref
        }
        else {
            self.run(with: scene)
        }
    }
    
    func present(scene: Scene, withTransition transition: Transition) {
        if runningScene != nil {
            self.sendCleanupToScene = true
            // the transition gets to become the running scene
            transition.startTransition(scene, withDirector: self)
        }
        else {
            self.run(with: scene)
        }
    }
    
    public func run(with scene: Scene) {
        assert(runningScene == nil, "This command can only be used to start the Director. There is already a scene present.")
        self.push(scene: scene)
        scene.director = self
        self.antiFlickrDrawCall()
        self.setNextScene()
        self.startRunLoop()
    }
    
    public func push(scene: Scene) {
        self.sendCleanupToScene = false
        scenesStack.add(scene)
        self.nextScene = scene
        // _nextScene is a weak ref
    }
    
    func push(scene: Scene, withTransition transition: Transition) {
        scenesStack.add(scene)
        self.sendCleanupToScene = false
        transition.startTransition(scene, withDirector: self)
    }
    
    func popScene() {
        assert(runningScene != nil, "A running Scene is needed")
        scenesStack.removeLastObject()
        let c: Int = scenesStack.count
        if c == 0 {
            self.end()
        }
        else {
            self.sendCleanupToScene = true
            self.nextScene = scenesStack[c - 1] as? Scene
        }
    }
    
    func popScene(with transition: Transition) {
        assert(runningScene != nil, "A running Scene is needed")
        if scenesStack.count < 2 {
            self.end()
        }
        else {
            scenesStack.removeLastObject()
            let incomingScene = scenesStack.lastObject as! Scene
            self.sendCleanupToScene = true
            transition.startTransition(incomingScene, withDirector: self)
        }
    }
    
    func popToRootScene() {
        self.popToSceneStackLevel(1)
    }
    
    func popToRootScene(with transition: Transition) {
        self.popToRootScene()
        self.sendCleanupToScene = true
        transition.startTransition(nextScene!, withDirector: self)
    }
    
    func popToSceneStackLevel(_ level: Int) {
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
    
    func start(transition: Transition) {
        assert(runningScene != nil, "There must be a running scene")
        scenesStack.removeLastObject()
        scenesStack.add(transition)
        self.nextScene = transition
    }
    
    func end() {
        runningScene!._onExitTransitionDidStart()
        runningScene!._onExit()
        runningScene!.cleanup()
        self.runningScene = nil
        self.nextScene = nil
        // remove all objects, but don't release it.
        // runWithScene might be executed after 'end'.
        scenesStack.removeAllObjects()
        self.stopRunLoop()
        //self.delegate = nil
        // Purge all managers / caches
        SpriteFrame.purgeCache()
        TextureCache.shared.removeUnusedTextures()
        FileLocator.shared.purgeCache()
    }
    
    func setNextScene() {
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
    
    func pause() {
        if isPaused {
            return
        }
        /*if ((delegate?.respondsToSelector(#selector(Director.pause))) != nil) {
            delegate?.pause!()
        }*/
        self.oldFrameSkipInterval = frameSkipInterval
        // when paused, don't consume CPU
        self.frameSkipInterval = 15
        self.willChangeValue(forKey: "isPaused")
        self.isPaused = true
        self.didChangeValue(forKey: "isPaused")
    }
    
    func resume() {
        if !isPaused {
            return
        }
        /*if ((delegate?.respondsToSelector(#selector(Director.resume))) != nil) {
            delegate!.resume!()
        }*/
        self.frameSkipInterval = oldFrameSkipInterval
        self.lastUpdate = Time.absoluteTime
        self.willChangeValue(forKey: "isPaused")
        self.isPaused = false
        self.didChangeValue(forKey: "isPaused")
        self.dt = 0
    }
}
