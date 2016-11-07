//
//  NSEvent+Fiber2d.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 11.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

#if os(OSX)
import SwiftMath
import Cocoa

public extension NSEvent {

    public var locationInWorld: Point {
        return Director.currentDirector!.convertEventToGL(self)
    }
    
    public func location(in node: Node) -> Point {
        let director = Director.currentDirector!
        let mouseLocation = director.convertEventToGL(self)
        return node.convertToNodeSpace(mouseLocation)
    }
    
}
#endif
