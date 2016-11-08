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
    
internal extension Director {
    internal func convertEventToGL(_ event: NSEvent) -> Point {
        let point: NSPoint = (self.view as! MetalView).convert(event.locationInWindow, from: nil)
        return self.convertToGL(Point(NSPointToCGPoint(point)))
    }
}
    
internal class MTKDelegate: NSObject, MTKViewDelegate {
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
        director.runningScene?.viewDidResize(to: Size(CGSize:size))
    }
}
#endif
