//
//  NSEvent+Fiber2d.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 11.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import Foundation
import SwiftMath

#if os(OSX)

extension NSEvent {

    var locationInWorld: Point {
        return Director.currentDirector!.convertEventToGL(self)
    }
    
    func location(in node: Node) -> Point {
        let director = Director.currentDirector!
        let mouseLocation = director.convertEventToGL(self)
        return node.convertToNodeSpace(mouseLocation)
    }
    
}
#endif
