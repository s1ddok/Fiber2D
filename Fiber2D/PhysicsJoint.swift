//
//  PhysicsJoint.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 18.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public class PhysicsJoint: Tagged {
    
    public var tag: Int = 0
    
    public var world: PhysicsWorld? = nil
    
    internal var chipmunkConstraints = [UnsafeMutablePointer<cpConstraint>]()
    
    public var bodyA: PhysicsBody?
    public var bodyB: PhysicsBody?
}
