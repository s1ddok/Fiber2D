//
//  Director+macOS.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 09.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

#if os(OSX)
import MetalKit
    
extension Director {
    func convertEventToGL(_ event: NSEvent) -> Point {
        let point: NSPoint = (self.view as! MetalView).convert(event.locationInWindow, from: nil)
        return self.convertToGL(Point(NSPointToCGPoint(point)))
    }
}
    
extension Director: MTKViewDelegate {
    public func draw(in view: MTKView) {
        self.animating = true
        self.mainLoopBody()
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        runningScene?.contentSize = Size(CGSize: size)
        runningScene?.viewDidResize(to: Size(CGSize:size))
    }
}
#endif
