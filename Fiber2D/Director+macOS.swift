//
//  Director+macOS.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 09.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

#if os(OSX) || os(iOS) || os(tvOS)
import SwiftMath
import MetalKit
import AppKit
    
// Temporary hack (see DirectorView)
public protocol _MTKDelegate { }
    
internal extension Director {
    internal func convertEventToGL(_ event: NSEvent) -> Point {
        if #available(OSX 10.11, *) {
            let point: NSPoint = (self.view as! NSView).convert(event.locationInWindow, from: nil)
            return self.convertToGL(Point(NSPointToCGPoint(point)))
        }
        return .zero
    }
}
    
@available(OSX, introduced: 10.11)
public class MTKDelegate: NSObject, MTKViewDelegate, _MTKDelegate {
    internal var director: Director
    
    internal init(director: Director) {
        self.director = director
        super.init()
    }
    
    public func draw(in view: MTKView) {
        director.animating = true
        director.mainLoopBody()
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        director.runningScene?.contentSize = Size(CGSize: size)
        director.runningScene?.onViewDidResize.fire(Size(CGSize: size))
    }
}
#endif
