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

func CCDirectorBindCurrent(director: AnyObject?) {
    if director != nil || !(director is NSNull) {
        NSThread.currentThread().threadDictionary[CCDirectorCurrentKey] = director
    } else {
        NSThread.currentThread().threadDictionary.removeObjectForKey(CCDirectorCurrentKey)
    }
}

func CCDirectorStack() -> NSMutableArray
{
    var stack = NSThread.currentThread().threadDictionary[CCDirectorStackKey] as? NSMutableArray
    if stack == nil {
        stack = NSMutableArray()
        NSThread.currentThread().threadDictionary[CCDirectorStackKey] = stack
    }
    return stack!
}

@objc class Director : NSObject, MTKViewDelegate {
    class func currentDirector() -> Director? {
        return NSThread.currentThread().threadDictionary[CCDirectorCurrentKey] as? Director
    }
    
    class func pushCurrentDirector(director: Director) {
        let stack = CCDirectorStack()
        stack.addObject(self.currentDirector() ?? NSNull())
        CCDirectorBindCurrent(director)
    }
    
    class func popCurrentDirector() {
        let stack = CCDirectorStack()
        assert(stack.count > 0, "CCDirector stack underflow.")
        CCDirectorBindCurrent(stack.lastObject)
        stack.removeLastObject()
    }
    
    // internal timer
    var oldFrameSkipInterval: Int = 1
    var frameSkipInterval: Int = 1
    /* stats */
    var displayStats: Bool
    var frames: Int
    var totalFrames: Int
    var secondsPerFrame: CCTime = 0.0
    var accumDt: CCTime = 0.0
    var frameRate: CCTime = 0.0
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
    var lastUpdate: CCTime = 0.0
    /* delta time since last tick to main loop */
    var dt: CCTime = 0.0
    /* whether or not the next delta time will be zero */
    var nextDeltaTimeZero: Bool = false
    //var rendererPool: [AnyObject]
    
    // Undocumented members (considered private)
    var responderManager: ResponderManager!
    //weak var delegate: CCDirectorDelegate?
    /// User definable value that is used for default contentSizes of many node types (Scene, NodeColor, etc).
    /// Defaults to the view size.
    var designSize : CGSize {
        get {
            // Return the viewSize unless designSize has been set.
            return (CGSizeEqualToSize(_designSize, CGSizeZero) ? self.viewSize() : _designSize)
        }
        
        set {
            _designSize = newValue
        }
    }
    private var _designSize = CGSizeZero
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
        var size: CGSize = self.viewSize
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
        var projection: GLKMatrix4 = runningScene!.projection
        // Synchronize the framebuffer with the view.
        framebuffer.syncWithView(self.view!)
        let renderer: CCRenderer = self.rendererFromPool()
    
        renderer.prepareWithProjection(&projection, framebuffer: framebuffer)
        CCRenderer.bindRenderer(renderer)
        renderer.enqueueClear(.Clear, color: runningScene!.colorRGBA.glkVector4, globalSortOrder: NSInteger.min)
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
    
    func poolRenderer(renderer: CCRenderer) {
        /*let lockQueue = dispatch_queue_create("com.test.LockQueue")
        dispatch_sync(lockQueue) {
            rendererPool.append(renderer)
        }*/
    }
    
    func addFrameCompletionHandler(handler: dispatch_block_t) {
        self.view!.addFrameCompletionHandler(handler)
    }
    
    func calculateDeltaTime() {
        let now: CCTime = CCAbsoluteTime()
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
        if Director.currentDirector()?.view != nil {
            CCTextureCache.sharedTextureCache().removeUnusedTextures()
        }
        CCFileLocator.sharedFileLocator().purgeCache()
    }
    
    func flipY() -> CGFloat {
        #if os(iOS)
        return -1.0
        #endif
        #if os(OSX)
        return 1.0
        #endif
    }
    
    func convertToGL(uiPoint: CGPoint) -> CGPoint {
        var transform: GLKMatrix4 = runningScene!.projection
        let invTransform: GLKMatrix4 = GLKMatrix4Invert(transform, nil)
        // Calculate z=0 using -> transform*[0, 0, 0, 1]/w
        let zClip: Float = transform.m.14 / transform.m.15
        let glSize: CGSize = self.view!.bounds.size
        var clipCoord: GLKVector3 = GLKVector3Make(2.0 * Float(uiPoint.x / glSize.width) - 1.0, 2.0 * Float(uiPoint.y / glSize.height) - 1.0, zClip)
        clipCoord.v.2 *= Float(self.flipY())
        let glCoord: GLKVector3 = GLKMatrix4MultiplyAndProjectVector3(invTransform, clipCoord)
        return ccp(CGFloat(glCoord.x), CGFloat(glCoord.y))
    }
    
    func convertToUI(glPoint: CGPoint) -> CGPoint {
        let transform: GLKMatrix4 = runningScene!.projection
        var clipCoord: GLKVector3 = GLKMatrix4MultiplyAndProjectVector3(transform, GLKVector3Make(Float(glPoint.x), Float(glPoint.y), 0.0))
        let glSize: CGSize = self.view!.bounds.size
        return ccp(glSize.width * CGFloat(clipCoord.v.0 * 0.5 + 0.5), glSize.height * CGFloat(Float(self.flipY()) * clipCoord.v.1 * 0.5 + 0.5))
    }
    
    func viewSize() -> CGSize {
        return CC_SIZE_SCALE(self.view!.sizeInPixels, 1.0 / CGFloat(CCSetup.sharedSetup().contentScale))
    }
    
    func viewSizeInPixels() -> CGSize {
        return self.view!.sizeInPixels
    }
    
    func viewportRect() -> CGRect {
        var projection: GLKMatrix4 = runningScene!.projection
        // TODO It's _possible_ that a user will use a non-axis aligned projection. Weird, but possible.
        let projectionInv: GLKMatrix4 = GLKMatrix4Invert(projection, nil)
        // Calculate z=0 using -> transform*[0, 0, 0, 1]/w
        let zClip: Float = projection.m.14 / projection.m.15
        // Bottom left and top right coords of viewport in clip coords.
        let clipBL: GLKVector3 = GLKVector3Make(-1.0, -1.0, zClip)
        let clipTR: GLKVector3 = GLKVector3Make(1.0, 1.0, zClip)
        // Bottom left and top right coords in GL coords.
        let glBL: GLKVector3 = GLKMatrix4MultiplyAndProjectVector3(projectionInv, clipBL)
        let glTR: GLKVector3 = GLKMatrix4MultiplyAndProjectVector3(projectionInv, clipTR)
        return CGRectMake(CGFloat(glBL.x), CGFloat(glBL.y), CGFloat(glTR.x - glBL.x), CGFloat(glTR.y - glBL.y))
    }
    
    func antiFlickrDrawCall() {
        // Questionable "anti-flickr", extra draw call:
        // overridden for android.
        self.mainLoopBody()
    }
    
    func presentScene(scene: Scene) {
        if runningScene != nil {
            self.sendCleanupToScene = true
            scenesStack.removeLastObject()
            scenesStack.addObject(scene)
            self.nextScene = scene
            // _nextScene is a weak ref
        }
        else {
            self.runWithScene(scene)
        }
    }
    
    func presentScene(scene: Scene, withTransition transition: Transition) {
        if runningScene != nil {
            self.sendCleanupToScene = true
            // the transition gets to become the running scene
            transition.startTransition(scene, withDirector: self)
        }
        else {
            self.runWithScene(scene)
        }
    }
    
    func runWithScene(scene: Scene!) {
        assert(scene != nil, "Argument must be non-nil")
        assert(runningScene == nil, "This command can only be used to start the CCDirector. There is already a scene present.")
        self.pushScene(scene)
        scene.director = self
        self.antiFlickrDrawCall()
        self.setNextScene()
        self.startRunLoop()
    }
    
    func pushScene(scene: Scene!) {
        assert(scene != nil, "Argument must be non-nil")
        self.sendCleanupToScene = false
        scenesStack.addObject(scene)
        self.nextScene = scene
        // _nextScene is a weak ref
    }
    
    func pushScene(scene: Scene!, withTransition transition: Transition) {
        assert(scene != nil, "Scene must be non-nil")
        scenesStack.addObject(scene)
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
    
    func popSceneWithTransition(transition: Transition) {
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
    
    func popToRootSceneWithTransition(transition: Transition) {
        self.popToRootScene()
        self.sendCleanupToScene = true
        transition.startTransition(nextScene!, withDirector: self)
    }
    
    func popToSceneStackLevel(level: Int) {
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
    
    func startTransition(transition: Transition!) {
        assert(transition != nil, "Argument must be non-nil")
        assert(runningScene != nil, "There must be a running scene")
        scenesStack.removeLastObject()
        scenesStack.addObject(transition)
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
        CCFileLocator.sharedFileLocator().purgeCache()
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
        self.willChangeValueForKey("isPaused")
        self.isPaused = true
        self.didChangeValueForKey("isPaused")
    }
    
    func resume() {
        if !isPaused {
            return
        }
        /*if ((delegate?.respondsToSelector(#selector(Director.resume))) != nil) {
            delegate!.resume!()
        }*/
        self.frameSkipInterval = oldFrameSkipInterval
        self.lastUpdate = CCAbsoluteTime()
        self.willChangeValueForKey("isPaused")
        self.isPaused = false
        self.didChangeValueForKey("isPaused")
        self.dt = 0
    }
    // This method is also overridden by platform specific directors.
    
    func startRunLoop() {
        self.nextDeltaTimeZero = true
    }
    
    func stopRunLoop() {
        print("Director#stopRunLoop. Override me")
    }
    
    func drawInMTKView(view: MTKView) {
        self.animating = true
        self.mainLoopBody()
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        runningScene?.contentSize = size
        runningScene?.viewDidResizeTo(size)
    }
    #if os(OSX)
    func convertEventToGL(event: NSEvent) -> CGPoint {
        let point: NSPoint = self.view!.convertPoint(event.locationInWindow, fromView: nil)
        return self.convertToGL(NSPointToCGPoint(point))
    }
    #endif
    
}