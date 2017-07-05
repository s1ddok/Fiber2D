//
//  DirectorView.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 09.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

// purposefully undocumented: used only internally
// Protocol for a view that Director will use to render into.
public protocol DirectorView: class {
    var sizeInPixels: Size { get }
    var size: Size { get }
    // Prepare the view to render a new frame.
    func beginFrame()
    
    // Schedule a block to be invoked when the frame completes.
    // The block may not be invoked from the main thread.
    // @param handler The completion block. The block takes no arguments and has no return value.
    func add(frameCompletionHandler handler: @escaping () -> ())
}
