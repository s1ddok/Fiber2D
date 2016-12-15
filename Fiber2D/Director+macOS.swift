//
//  Director+macOS.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 09.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

#if os(OSX)
import SwiftMath
import AppKit

internal extension Director {
    internal func convertEventToGL(_ event: NSEvent) -> Point {
        if #available(OSX 10.11, *) {
            let point: NSPoint = (self.view as! NSView).convert(event.locationInWindow, from: nil)
            return self.convertToGL(Point(NSPointToCGPoint(point)))
        }
        return .zero
    }
}
    
#endif
