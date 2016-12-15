//
//  Window+Fiber2D.swift
//  Fiber2D-demo
//
//  Created by Andrey Volodin on 15.12.16.
//
//

import SwiftMath
import Fiber2D

extension Window: DirectorView {
    public func add(frameCompletionHandler handler: @escaping () -> ()) { }
    
    public var sizeInPixels: Size {
        return Size(width, height)
    }
    
    public var size: Size {
        return Size(width, height)
    }
    
    // Prepare the view to render a new frame.
    public func beginFrame() {}
    
    // Present the current frame to the display.
    public func presentFrame() {}
}
