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

internal func internalBodyUpdateVelocity(_ body: UnsafeMutablePointer<cpBody>?, _ gravity: cpVect, _ damping: cpFloat, _ dt: cpFloat) {
    cpBodyUpdateVelocity(body, cpvzero, damping, dt)
    // Skip kinematic bodies.
    guard cpBodyGetType(body) != CP_BODY_TYPE_KINEMATIC else {
        return
    }

    let physicsBody = Unmanaged<PhysicsBody>.fromOpaque(cpBodyGetUserData(body)).takeUnretainedValue()
    
    if physicsBody.isGravityEnabled {
        body!.pointee.v = cpvclamp(cpvadd(cpvmult(body!.pointee.v, damping), cpvmult(cpvadd(gravity, cpvmult(body!.pointee.f, body!.pointee.m_inv)), dt)), cpFloat(physicsBody.velocityLimit))
    } else {
        body!.pointee.v = cpvclamp(cpvadd(cpvmult(body!.pointee.v, damping), cpvmult(cpvmult(body!.pointee.f, body!.pointee.m_inv), dt)), cpFloat(physicsBody.velocityLimit))
    }
    let w_limit = cpFloat(physicsBody.angularVelocityLimit)
    body!.pointee.w = cpfclamp(body!.pointee.w * damping + body!.pointee.t * body!.pointee.i_inv * dt, -w_limit, w_limit)
    
    // Reset forces.
    body!.pointee.f = cpvzero
    //to check body sanity
    cpBodySetTorque(body, 0.0)
}
