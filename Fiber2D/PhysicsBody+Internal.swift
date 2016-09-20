//
//  PhysicsBody+Internal.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 20.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

internal func internalBodySetMass(_ body: UnsafeMutablePointer<cpBody>, _ mass: cpFloat)
{
    cpBodyActivate(body);
    body.pointee.m = mass;
    body.pointee.m_inv = 1.0 / mass
    //cpAssertSaneBody(body);
}

func internalBodyUpdateVelocity(_ body: UnsafeMutablePointer<cpBody>?, _ gravity: cpVect, _ damping: cpFloat, _ dt: cpFloat) {
    
}
