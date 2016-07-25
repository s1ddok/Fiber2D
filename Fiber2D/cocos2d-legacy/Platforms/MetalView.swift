//
//  MetalView.swift
//
//  Created by Andrey Volodin on 07.06.16.
//  Copyright © 2016. All rights reserved.
//

import MetalKit

class MetalView : MTKView {
    var context: CCMetalContext!
    //id<MTLDrawable> _currentDrawable;
    var layerSizeDidUpdate: Bool = false
    var director: Director!
    var surfaceSize = CGSizeZero
    
    var sizeInPixels: CGSize {
        get {
            return CC_SIZE_SCALE(self.bounds.size, self.contentScaleFactor)
        }
    }
    
    #if os(OSX)
    var contentScaleFactor: CGFloat {
        get {
            let screen = NSScreen.mainScreen()!
            return screen.backingScaleFactor
        }
    }
    
    override var acceptsFirstResponder : Bool {
        get {
            return true
        }
    }
    #endif
    
    init(frame: CGRect) {
        self.context = CCMetalContext()
        super.init(frame: frame, device: context.device)
        
        //TODO Move into CCRenderDispatch to support threaded rendering with Metal?
        CCMetalContext.setCurrentContext(context)
        self.device = context.device
        self.framebufferOnly = true
        /*CAMetalLayer *layer = self.metalLayer;
         layer.opaque = YES;
         layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
         layer.framebufferOnly = YES;
         
         layer.device = _context.device;
         layer.pixelFormat = MTLPixelFormatBGRA8Unorm;*/
        /*self.opaque = true
        self.backgroundColor = nil
        // Default to the screen's native scale.
        var screen: UIScreen = UIScreen.mainScreen()
        if screen.respondsToSelector("nativeScale") {
            self.contentScaleFactor = screen.nativeScale
        }
        else {
            self.contentScaleFactor = screen.scale
        }
        self.multipleTouchEnabled = true
        self.director = DirectorDisplayLink(view: self)*/
        self.director = Director(view: self)
        self.preferredFramesPerSecond = 60
        self.delegate = director
        self.drawableSize = frame.size
        self.surfaceSize = frame.size
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.context = CCMetalContext()
        //TODO Move into CCRenderDispatch to support threaded rendering with Metal?
        CCMetalContext.setCurrentContext(context)
        self.device = context.device
        self.framebufferOnly = true
        self.director = Director(view: self)
        self.preferredFramesPerSecond = 60
        self.delegate = director
        self.sampleCount = 4
    }
    
    func layoutSubviews() {
        self.layerSizeDidUpdate = true
        self.surfaceSize = CC_SIZE_SCALE(self.bounds.size, self.contentScaleFactor)
    }
    
    func beginFrame() {
        //dispatch_semaphore_wait(_queuedFramesSemaphore, DISPATCH_TIME_FOREVER);
        if layerSizeDidUpdate {
            self.drawableSize = surfaceSize
            self.layerSizeDidUpdate = false
        }
        
    }
    
    func presentFrame() {
        context.currentCommandBuffer.presentDrawable(self.currentDrawable!)
        context.flushCommandBuffer()
    }
    
    func addFrameCompletionHandler(handler: dispatch_block_t) {
        context.currentCommandBuffer.addCompletedHandler({(buffer: MTLCommandBuffer) -> Void in
            handler()
        })
    }
    
    func convertPointFromViewToSurface(point: CGPoint) -> CGPoint {
        let bounds: CGRect = self.bounds
        return CGPointMake((point.x - bounds.origin.x) / bounds.size.width * surfaceSize.width, (point.y - bounds.origin.y) / bounds.size.height * surfaceSize.height)
    }
    
    func convertRectFromViewToSurface(rect: CGRect) -> CGRect {
        let bounds: CGRect = self.bounds
        return CGRectMake((rect.origin.x - bounds.origin.x) / bounds.size.width * surfaceSize.width, (rect.origin.y - bounds.origin.y) / bounds.size.height * surfaceSize.height, rect.size.width / bounds.size.width * surfaceSize.width, rect.size.height / bounds.size.height * surfaceSize.height)
    }
    #if os(iOS)
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        Director.pushCurrentDirector(director)
        director.responderManager.touchesBegan(touches, withEvent: event)
        Director.popCurrentDirector()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        Director.pushCurrentDirector(director)
        director.responderManager.touchesMoved(touches, withEvent: event)
        Director.popCurrentDirector()
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        Director.pushCurrentDirector(director)
        director.responderManager.touchesEnded(touches, withEvent: event)
        Director.popCurrentDirector()
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        Director.pushCurrentDirector(director)
        director.responderManager.touchesCancelled(touches, withEvent: event)
        Director.popCurrentDirector()
    }
    #endif
    
    #if os(OSX)
    // NSResponder Mac events are forwarded to the responderManager associated with this view's Director.
    
    override func mouseDown(theEvent: NSEvent) {
        director.responderManager.mouseDown(theEvent, button: .left)
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        director.responderManager.mouseDragged(theEvent, button: .left)
    }
    
    override func mouseUp(theEvent: NSEvent) {
        director.responderManager.mouseUp(theEvent, button: .left)
    }
    
    override func mouseMoved(theEvent: NSEvent) {
        director.responderManager.mouseMoved(theEvent)
    }
    
    override func rightMouseDown(theEvent: NSEvent) {
        director.responderManager.mouseDown(theEvent, button: .right)
    }
    
    override func rightMouseDragged(theEvent: NSEvent) {
        director.responderManager.mouseDragged(theEvent, button: .right)
    }
    
    override func rightMouseUp(theEvent: NSEvent) {
        director.responderManager.mouseUp(theEvent, button: .right)
    }
    
    override func otherMouseDown(theEvent: NSEvent) {
        director.responderManager.mouseDown(theEvent, button: .other)
    }
    
    override func otherMouseDragged(theEvent: NSEvent) {
        director.responderManager.mouseDragged(theEvent, button: .other)
    }
    
    override func otherMouseUp(theEvent: NSEvent) {
        director.responderManager.mouseUp(theEvent, button: .other)
    }
    
    override func scrollWheel(theEvent: NSEvent) {
        director.responderManager.scrollWheel(theEvent)
    }
    
    override func keyDown(theEvent: NSEvent) {
        director.responderManager.keyDown(theEvent)
    }
    
    override func keyUp(theEvent: NSEvent) {
        director.responderManager.keyUp(theEvent)
    }
    
    override func flagsChanged(theEvent: NSEvent) {
        director.responderManager.flagsChanged(theEvent)
    }
    #endif
}