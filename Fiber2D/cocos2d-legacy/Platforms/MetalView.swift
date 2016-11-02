//
//  MetalView.swift
//
//  Created by Andrey Volodin on 07.06.16.
//  Copyright © 2016. All rights reserved.
//

import Metal
import MetalKit
import SwiftMath

class MetalView: MTKView, DirectorView {
    var layerSizeDidUpdate: Bool = false
    var director: Director!
    var surfaceSize = CGSize.zero
    
    var sizeInPixels: Size {
        return Size(CGSize: self.bounds.size) *  Float(self.contentScaleFactor)
    }
    
    var size: Size {
        return Size(CGSize: self.bounds.size)
    }
    
    #if os(OSX)
    var contentScaleFactor: CGFloat {
        let screen = NSScreen.main()!
        return screen.backingScaleFactor
    }
    
    override var acceptsFirstResponder : Bool {
        return true
    }
    #endif
    
    init(frame: CGRect) {
        super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
        self.framebufferOnly = true

        self.director = Director(view: self)
        self.preferredFramesPerSecond = 60
        self.delegate = director
        self.drawableSize = frame.size
        self.surfaceSize = frame.size
        self.colorPixelFormat = .bgra8Unorm
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        //self.context = CCMetalContext()
        //TODO Move into CCRenderDispatch to support threaded rendering with Metal?
        //CCMetalContext.setCurrent(context)
        /*self.device = context.device
        self.framebufferOnly = true
        self.director = Director(view: self)
        self.preferredFramesPerSecond = 60
        self.delegate = director
        self.sampleCount = 4*/
    }
    
    func layoutSubviews() {
        self.layerSizeDidUpdate = true
        self.surfaceSize = (Size(CGSize: self.bounds.size) * Float(self.contentScaleFactor)).cgSize
    }
    
    func beginFrame() {
        //dispatch_semaphore_wait(_queuedFramesSemaphore, DISPATCH_TIME_FOREVER);
        if layerSizeDidUpdate {
            self.drawableSize = surfaceSize
            self.layerSizeDidUpdate = false
        }
        
    }
    
    func presentFrame() {
        //context.currentCommandBuffer.present(self.currentDrawable!)
        //context.flushCommandBuffer()
    }
    
    func add(frameCompletionHandler handler: @escaping ()->()) {
        /*context.currentCommandBuffer.addCompletedHandler {(buffer: MTLCommandBuffer) -> Void in
            handler()
        }*/
    }
    
    func convertPointFromViewToSurface(_ point: CGPoint) -> CGPoint {
        let bounds: CGRect = self.bounds
        return CGPoint(x: (point.x - bounds.origin.x) / bounds.size.width * surfaceSize.width, y: (point.y - bounds.origin.y) / bounds.size.height * surfaceSize.height)
    }
    
    func convertRectFromViewToSurface(_ rect: CGRect) -> CGRect {
        let bounds: CGRect = self.bounds
        return CGRect(x: (rect.origin.x - bounds.origin.x) / bounds.size.width * surfaceSize.width, y: (rect.origin.y - bounds.origin.y) / bounds.size.height * surfaceSize.height, width: rect.size.width / bounds.size.width * surfaceSize.width, height: rect.size.height / bounds.size.height * surfaceSize.height)
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
    
    override func mouseDown(with theEvent: NSEvent) {
        director.responderManager.mouseDown(theEvent, button: .left)
    }
    
    override func mouseDragged(with theEvent: NSEvent) {
        director.responderManager.mouseDragged(theEvent, button: .left)
    }
    
    override func mouseUp(with theEvent: NSEvent) {
        director.responderManager.mouseUp(theEvent, button: .left)
    }
    
    override func mouseMoved(with theEvent: NSEvent) {
        director.responderManager.mouseMoved(theEvent)
    }
    
    override func rightMouseDown(with theEvent: NSEvent) {
        director.responderManager.mouseDown(theEvent, button: .right)
    }
    
    override func rightMouseDragged(with theEvent: NSEvent) {
        director.responderManager.mouseDragged(theEvent, button: .right)
    }
    
    override func rightMouseUp(with theEvent: NSEvent) {
        director.responderManager.mouseUp(theEvent, button: .right)
    }
    
    override func otherMouseDown(with theEvent: NSEvent) {
        director.responderManager.mouseDown(theEvent, button: .other)
    }
    
    override func otherMouseDragged(with theEvent: NSEvent) {
        director.responderManager.mouseDragged(theEvent, button: .other)
    }
    
    override func otherMouseUp(with theEvent: NSEvent) {
        director.responderManager.mouseUp(theEvent, button: .other)
    }
    
    override func scrollWheel(with theEvent: NSEvent) {
        director.responderManager.scrollWheel(theEvent)
    }
    
    override func keyDown(with theEvent: NSEvent) {
        director.responderManager.keyDown(theEvent)
    }
    
    override func keyUp(with theEvent: NSEvent) {
        director.responderManager.keyUp(theEvent)
    }
    
    override func flagsChanged(with theEvent: NSEvent) {
        director.responderManager.flagsChanged(theEvent)
    }
    #endif
}
