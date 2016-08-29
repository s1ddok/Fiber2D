//
//  Director.swift
//
//  Created by Andrey Volodin on 08.06.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation
import MetalKit

let CCDirectorCurrentKey = "CCDirectorCurrentKey"
let CCDirectorStackKey   = "CCDirectorStackKey"

func CCDirectorBindCurrent(_ director: AnyObject?) {
    if director != nil || !(director is NSNull) {
        Thread.current.threadDictionary[CCDirectorCurrentKey] = director
    } else {
        Thread.current.threadDictionary.removeObject(forKey: CCDirectorCurrentKey)
    }
}

func CCDirectorStack() -> NSMutableArray
{
    var stack = Thread.current.threadDictionary[CCDirectorStackKey] as? NSMutableArray
    if stack == nil {
        stack = NSMutableArray()
        Thread.current.threadDictionary[CCDirectorStackKey] = stack
    }
    return stack!
}

@objc class Director : NSObject, MTKViewDelegate {
    class var currentDirector: Director? {
        return Thread.current.threadDictionary[CCDirectorCurrentKey] as? Director
    }
    
    class func pushCurrentDirector(_ director: Director) {
        let stack = CCDirectorStack()
        stack.add(self.currentDirector ?? NSNull())
        CCDirectorBindCurrent(director)
    }
    
    class func popCurrentDirector() {
        let stack = CCDirectorStack()
        assert(stack.count > 0, "CCDirector stack underflow.")
        CCDirectorBindCurrent(stack.lastObject as AnyObject?)
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
    var nextScene: Scene?
    /* If YES, then "old" scene will receive the cleanup message */
    var sendCleanupToScene: Bool = false
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
    //weak var delegate: CCDirectorDelegate?
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
    /// View used by the director for rendering. The CC_VIEW macro equals UIView on iOS, NSOpenGLView on OS X and MetalView on Android.
    /// @see MetalView
    weak var view: MetalView?
    
    /// The current global shader values values.
    var globalShaderUniforms = Dictionary<String, AnyObject>()
    
    let framebuffer = CCFrameBufferObjectMetal()
    
    init(view: MetalView) {
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
    
    func mainLoopBody() {
        if !animating {
            return
        }
        Director.pushCurrentDirector(self)
        /* calculate "global" dt */
        self.calculateDeltaTime()
        /* tick before glClear: issue #533 */
        if !isPaused {
            runningScene!.scheduler.update(dt)
        }
        /* to avoid flickr, nextScene MUST be here: after tick and before draw.
         XXX: Which bug is this one. It seems that it can't be reproduced with v0.9 */
        if nextScene != nil {
            self.setNextScene()
        }
        view!.beginFrame()
        let projection = runningScene!.projection
        // Synchronize the framebuffer with the view.
        framebuffer.sync(with: self.view!)
        let renderer: CCRenderer = self.rendererFromPool()
    
        var proj = projection.glkMatrix4
        renderer.prepare(withProjection: &proj, framebuffer: framebuffer)
        CCRenderer.bindRenderer(renderer)
        renderer.enqueueClear(.clear, color: runningScene!.colorRGBA.glkVector4, globalSortOrder: NSInteger.min)
        // Render
        runningScene!.visit(renderer, parentTransform: projection)
        notificationNode?.visit(renderer, parentTransform: projection)

        CCRenderer.bindRenderer(nil)
        view!.addFrameCompletionHandler {
            // Return the renderer to the pool when the frame completes.
            self.poolRenderer(renderer)
        }
        renderer.flush()
        view!.presentFrame()
        totalFrames += 1
        Director.popCurrentDirector()
    }
    
    func rendererFromPool() -> CCRenderer {
        /*let lockQueue = dispatch_queue_create("com.test.LockQueue")
        dispatch_sync(lockQueue) {
            if rendererPool.count > 0 {
                var renderer: CCRenderer = rendererPool.lastObject
                rendererPool.removeLastObject()
                return renderer
            }
        }*/
        // Allocate and return a new renderer.
        return CCRenderer()
    }
    
    func poolRenderer(_ renderer: CCRenderer) {
        /*let lockQueue = dispatch_queue_create("com.test.LockQueue")
        dispatch_sync(lockQueue) {
            rendererPool.append(renderer)
        }*/
    }
    
    func addFrameCompletionHandler(_ handler: @escaping ()->()) {
        self.view!.addFrameCompletionHandler(handler)
    }
    
    func calculateDeltaTime() {
        let now: Time = Time(CCAbsoluteTime())
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
        /*if ((delegate?.respondsToSelector(#selector(CCDirectorDelegate.purgeCachedData))) != nil) {
            delegate?.purgeCachedData!()
        }*/
        CCRenderState.flushCache()
        if Director.currentDirector?.view != nil {
            CCTextureCache.shared().removeUnusedTextures()
        }
        CCFileLocator.shared().purgeCache()
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
        let glSize: Size = Size(CGSize: self.view!.bounds.size)
        var clipCoord = vec3(2.0 * Float(uiPoint.x / glSize.width) - 1.0, 2.0 * Float(uiPoint.y / glSize.height) - 1.0, zClip)
        clipCoord.y *= flipY
        return invTransform.multiplyAndProject(v: clipCoord).xy
    }
    
    func convertToUI(_ glPoint: Point) -> Point {
        let transform = runningScene!.projection
        let clipCoord = transform.multiplyAndProject(v: glPoint.extendedToVec3)
        let glSize: Size = Size(CGSize: self.view!.bounds.size)
        return glSize * p2d(clipCoord.x * 0.5 + 0.5, clipCoord.y * flipY * 0.5 + 0.5)
    }
    
    var viewSize: Size {
        return viewSizeInPixels * Float(1.0 / CCSetup.shared().contentScale)
    }
    
    var viewSizeInPixels: Size {
        return Size(CGSize: self.view!.sizeInPixels)
    }
    
    var viewportRect: Rect {
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
    
    func antiFlickrDrawCall() {
        // Questionable "anti-flickr", extra draw call:
        // overridden for android.
        self.mainLoopBody()
    }
    
    func presentScene(_ scene: Scene) {
        if runningScene != nil {
            self.sendCleanupToScene = true
            scenesStack.removeLastObject()
            scenesStack.add(scene)
            self.nextScene = scene
            // _nextScene is a weak ref
        }
        else {
            self.runWithScene(scene)
        }
    }
    
    func presentScene(_ scene: Scene, withTransition transition: Transition) {
        if runningScene != nil {
            self.sendCleanupToScene = true
            // the transition gets to become the running scene
            transition.startTransition(scene, withDirector: self)
        }
        else {
            self.runWithScene(scene)
        }
    }
    
    func runWithScene(_ scene: Scene!) {
        assert(scene != nil, "Argument must be non-nil")
        assert(runningScene == nil, "This command can only be used to start the CCDirector. There is already a scene present.")
        self.pushScene(scene)
        scene.director = self
        self.antiFlickrDrawCall()
        self.setNextScene()
        self.startRunLoop()
    }
    
    func pushScene(_ scene: Scene!) {
        assert(scene != nil, "Argument must be non-nil")
        self.sendCleanupToScene = false
        scenesStack.add(scene)
        self.nextScene = scene
        // _nextScene is a weak ref
    }
    
    func pushScene(_ scene: Scene!, withTransition transition: Transition) {
        assert(scene != nil, "Scene must be non-nil")
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
    
    func popSceneWithTransition(_ transition: Transition) {
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
    
    func popToRootSceneWithTransition(_ transition: Transition) {
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
                current.onExitTransitionDidStart()
                current.onExit()
            }
            current.cleanup()
            scenesStack.removeLastObject()
            c -= 1
        }
        self.nextScene = scenesStack.lastObject as? Scene
        self.sendCleanupToScene = false
    }
    
    func startTransition(_ transition: Transition!) {
        assert(transition != nil, "Argument must be non-nil")
        assert(runningScene != nil, "There must be a running scene")
        scenesStack.removeLastObject()
        scenesStack.add(transition)
        self.nextScene = transition
    }
    
    func end() {
        /*if ((delegate?.respondsToSelector(#selector(CCDirectorDelegate.end))) != nil) {
            delegate!.end!()
        }*/
        runningScene!.onExitTransitionDidStart()
        runningScene!.onExit()
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
        CCTextureCache.purgeSharedTextureCache()
        CCFileLocator.shared().purgeCache()
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
            runningScene!.onEnter()
            return
        }
        // If running scene is a transition class, the transition has ended
        // Make new scene, the running scene
        // Clean up transition
        // Outgoing scene was stopped by transition
        if (runningScene is Transition) {
            runningScene!.onExit()
            runningScene!.cleanup()
            self.runningScene!.director = nil
            self.runningScene = nil
            self.runningScene = nextScene
            self.nextScene = nil
            return
        }
        // if next scene is not a transition, force exit calls
        if !(nextScene is Transition) {
            runningScene?.onExitTransitionDidStart()
            runningScene?.onExit()
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
            runningScene!.onEnter()
            runningScene!.onEnterTransitionDidFinish()
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
        self.lastUpdate = Time(CCAbsoluteTime())
        self.willChangeValue(forKey: "isPaused")
        self.isPaused = false
        self.didChangeValue(forKey: "isPaused")
        self.dt = 0
    }
    // This method is also overridden by platform specific directors.
    
    func startRunLoop() {
        self.nextDeltaTimeZero = true
    }
    
    func stopRunLoop() {
        print("Director#stopRunLoop. Override me")
    }
    
    func draw(in view: MTKView) {
        self.animating = true
        self.mainLoopBody()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        runningScene?.contentSize = Size(CGSize: size)
        runningScene?.viewDidResizeTo(Size(CGSize:size))
    }
    #if os(OSX)
    func convertEventToGL(_ event: NSEvent) -> Point {
        let point: NSPoint = self.view!.convert(event.locationInWindow, from: nil)
        return self.convertToGL(Point(NSPointToCGPoint(point)))
    }
    #endif
    
}
