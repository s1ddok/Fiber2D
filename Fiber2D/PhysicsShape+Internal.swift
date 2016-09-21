//
//  PhysicsShape+Internal.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 20.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

internal extension PhysicsShape {
    func add(shape: UnsafeMutablePointer<cpShape>) {
        cpShapeSetUserData(shape, Unmanaged.passRetained(self).toOpaque())
        cpShapeSetFilter(shape, cpShapeFilterNew(cpGroup(group), CP_ALL_CATEGORIES, CP_ALL_CATEGORIES))
        chipmunkShapes.append(shape)
    }
    
}

internal let SHARED_BODY = cpBodyNewStatic()
