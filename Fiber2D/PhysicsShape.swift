//
//  PhysicsShape.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 20.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public class PhysicsShape {
    
    internal(set) public var chipmunkShapes = [UnsafeMutablePointer<cpShape>]()
}
