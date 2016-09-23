//
//  PhysicsWorld+Shapes.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 20.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

internal extension PhysicsWorld {
    
    internal func add(shape: PhysicsShape) {
        for cps in shape.chipmunkShapes {
            cpSpaceAddShape(chipmunkSpace, cps)
        }
    }
    
    internal func remove(shape: PhysicsShape) {
        for cps in shape.chipmunkShapes {
            if cpSpaceContainsShape(chipmunkSpace, cps) != 0 {
                cpSpaceRemoveShape(chipmunkSpace, cps)
            }
        }
    }
}
