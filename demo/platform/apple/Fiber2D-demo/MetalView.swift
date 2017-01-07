//
//  MetalView.swift
//
//  Created by Andrey Volodin on 07.06.16.
//  Copyright © 2016. All rights reserved.
//

import Metal
import MetalKit
import SwiftMath
import Fiber2D

@available(OSX, introduced: 10.11)
public class MTKDelegate: NSObject, MTKViewDelegate {
    internal var director: Director
    
    internal init(director: Director) {
        self.director = director
        super.init()
    }
    
    public func draw(in view: MTKView) {
        director.mainLoopBody()
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        director.runningScene?.contentSize = Size(CGSize: size)
        director.runningScene?.onViewDidResize.fire(Size(CGSize: size))
    }
}

public class MetalView: MTKView, DirectorView {
    var layerSizeDidUpdate: Bool = false
    var director: Director!
    var surfaceSize = CGSize.zero
    var directorDelegate: MTKDelegate!
    
    public var sizeInPixels: Size {
        return Size(CGSize: self.bounds.size) *  Float(self.contentScaleFactor)
    }
    
    public var size: Size {
        return Size(CGSize: self.bounds.size)
    }
    
    #if os(OSX)
    var contentScaleFactor: CGFloat {
        let screen = NSScreen.main()!
        return screen.backingScaleFactor
    }
    
    override public var acceptsFirstResponder : Bool {
        return true
    }
    #endif
    
    init(frame: CGRect) {
        super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
        self.framebufferOnly = true

        self.director = Director(view: self)
        self.preferredFramesPerSecond = 60
        self.directorDelegate = MTKDelegate(director: self.director)
        self.delegate = directorDelegate
        self.drawableSize = frame.size
        self.surfaceSize = frame.size
        self.colorPixelFormat = .bgra8Unorm
    }
    
    required public init(coder: NSCoder) {
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
    
    override public func layoutSubviews() {
        self.layerSizeDidUpdate = true
        self.surfaceSize = (Size(CGSize: self.bounds.size) * Float(self.contentScaleFactor)).cgSize
    }
    
    public func beginFrame() {
        //dispatch_semaphore_wait(_queuedFramesSemaphore, DISPATCH_TIME_FOREVER);
        if layerSizeDidUpdate {
            self.drawableSize = surfaceSize
            self.layerSizeDidUpdate = false
        }
        
    }
    
    public func presentFrame() {
        //context.currentCommandBuffer.present(self.currentDrawable!)
        //context.flushCommandBuffer()
    }
    
    public func add(frameCompletionHandler handler: @escaping ()->()) {
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
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        Director.pushCurrentDirector(director)
        director.responderManager.touchesBegan(touches, with: event)
        Director.popCurrentDirector()
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        Director.pushCurrentDirector(director)
        director.responderManager.touchesMoved(touches, with: event)
        Director.popCurrentDirector()
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        Director.pushCurrentDirector(director)
        director.responderManager.touchesEnded(touches, with: event)
        Director.popCurrentDirector()
    }

    override public func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        Director.pushCurrentDirector(director)
        director.responderManager.touchesCancelled(touches ?? Set<UITouch>(), with: event)
        Director.popCurrentDirector()
    }
    #endif
    
    #if os(OSX)
    // NSResponder Mac events are forwarded to the responderManager associated with this view's Director.
    
    override public func mouseDown(with theEvent: NSEvent) {
        director.responderManager.mouseDown(theEvent, button: .left)
    }
    
    override public func mouseDragged(with theEvent: NSEvent) {
        director.responderManager.mouseDragged(theEvent, button: .left)
    }
    
    override public func mouseUp(with theEvent: NSEvent) {
        director.responderManager.mouseUp(theEvent, button: .left)
    }
    
    override public func mouseMoved(with theEvent: NSEvent) {
        director.responderManager.mouseMoved(theEvent)
    }
    
    override public func rightMouseDown(with theEvent: NSEvent) {
        director.responderManager.mouseDown(theEvent, button: .right)
    }
    
    override public func rightMouseDragged(with theEvent: NSEvent) {
        director.responderManager.mouseDragged(theEvent, button: .right)
    }
    
    override public func rightMouseUp(with theEvent: NSEvent) {
        director.responderManager.mouseUp(theEvent, button: .right)
    }
    
    override public func otherMouseDown(with theEvent: NSEvent) {
        director.responderManager.mouseDown(theEvent, button: .other)
    }
    
    override public func otherMouseDragged(with theEvent: NSEvent) {
        director.responderManager.mouseDragged(theEvent, button: .other)
    }
    
    override public func otherMouseUp(with theEvent: NSEvent) {
        director.responderManager.mouseUp(theEvent, button: .other)
    }
    
    override public func scrollWheel(with theEvent: NSEvent) {
        director.responderManager.scrollWheel(theEvent)
    }
    
    override public func keyDown(with theEvent: NSEvent) {
        director.responderManager.keyDown(theEvent)
    }
    
    override public func keyUp(with theEvent: NSEvent) {
        director.responderManager.keyUp(theEvent)
    }
    
    override public func flagsChanged(with theEvent: NSEvent) {
        director.responderManager.flagsChanged(theEvent)
    }
    #endif
}
