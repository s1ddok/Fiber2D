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
    
    /**
     * @brief Add moment of inertia to body.
     *
     * @param moment If _moment(moment of the body) == PHYSICS_INFINITY, it remains.
     * if moment == PHYSICS_INFINITY, _moment will be PHYSICS_INFINITY.
     * if moment == -PHYSICS_INFINITY, _moment will not change.
     * if moment + _moment <= 0, _moment will equal to MASS_DEFAULT(1.0)
     * other wise, moment = moment + _moment;
     */
    public func add(moment: Float) {
        if moment == PHYSICS_INFINITY {
            // if moment is PHYSICS_INFINITY, the moment of the body will become PHYSICS_INFINITY
            _moment = PHYSICS_INFINITY
            _momentDefault = false
        } else if moment == -PHYSICS_INFINITY {
            return
        } else {
            // if moment of the body is PHYSICS_INFINITY is has no effect
            if _moment != PHYSICS_INFINITY {
                if _momentDefault {
                    _moment = 0
                    _momentDefault = false
                }
                
                if _moment + moment > 0 {
                    _moment += moment
                } else {
                    _moment = MOMENT_DEFAULT
                    _momentDefault = true
                }
            }
        }
        
        // the static body's mass and moment is always infinity
        if isRotationEnabled && isDynamic {
            cpBodySetMoment(chipmunkBody, cpFloat(_moment));
        }
    }
    
    /**
     * @brief Add mass to body.
     *
     * @param mass If _mass(mass of the body) == PHYSICS_INFINITY, it remains.
     * if mass == PHYSICS_INFINITY, _mass will be PHYSICS_INFINITY.
     * if mass == -PHYSICS_INFINITY, _mass will not change.
     * if mass + _mass <= 0, _mass will equal to MASS_DEFAULT(1.0)
     * other wise, mass = mass + _mass;
     */
    public func add(mass: Float) {
        if mass == PHYSICS_INFINITY {
            _mass = PHYSICS_INFINITY
            _massDefault = false
            _density = PHYSICS_INFINITY
        }
        else if mass == -PHYSICS_INFINITY {
            return
        } else {
            if _massDefault {
                _mass = 0
                _massDefault = false
            }
            
            if _mass + mass > 0 {
                _mass +=  mass;
            } else {
                _mass = MASS_DEFAULT
                _massDefault = true
            }
            
            if _area > 0 {
                _density = _mass / _area
            } else {
                _density = 0
            }
        }
        
        // the static body's mass and moment is always infinity
        if isDynamic {
            internalBodySetMass(chipmunkBody, cpFloat(_mass));
        }
    }
}

internal func internalBodySetMass(_ body: UnsafeMutablePointer<cpBody>, _ mass: cpFloat)
{
    cpBodyActivate(body);
    body.pointee.m = mass;
    body.pointee.m_inv = 1.0 / mass
    //cpAssertSaneBody(body);
}

