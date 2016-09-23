//
//  PhysicsBody+Joints.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 20.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public extension PhysicsBody {
    
    internal func remove(joint: PhysicsJoint) {
        joints.removeObject(joint)
    }
}
