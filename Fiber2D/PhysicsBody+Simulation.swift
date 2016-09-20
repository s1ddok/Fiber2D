//
//  PhysicsBody+Simulation.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 20.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public extension PhysicsBody {
    /**
     * Applies a continuous force to body.
     *
     * @param force The force is applies to this body.
     * @param offset A Vec2 object, it is the offset from the body's center of gravity in world coordinates.
     */
    public func apply(force: Vector2f, offset: Vector2f = Vector2f.zero) {
        if isDynamic && mass != Float.infinity {
            cpBodyApplyForceAtLocalPoint(chipmunkBody, cpVect(force), cpVect(offset))
        }
    }
    
    /**
     * reset all the force applied to body.
     */
    public func resetForces() {
        cpBodySetForce(chipmunkBody, cpVect(vec2.zero))
    }
    
    /**
     * Applies a torque force to body.
     *
     * @param torque The torque is applies to this body.
     */
    public func apply(torque: Float) {
        cpBodySetTorque(chipmunkBody, cpFloat(torque))
    }
    
    /**
     * Applies a immediate force to body.
     *
     * @param impulse The impulse is applies to this body.
     * @param offset A Vec2 object, it is the offset from the body's center of gravity in world coordinates.
     */
    public func apply(impulse: Vector2f, offset: Vector2f = Vector2f.zero) {
        cpBodyApplyImpulseAtLocalPoint(chipmunkBody, cpVect(impulse), cpVect(offset));
    }
}
