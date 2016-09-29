//
//  PhysicsShape.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 20.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

public enum PhysicsShapeType {
    case unknown, circle, box, polygon
    case edgeSegment, edgeBox, edgePolygon, edgeChain
}

public struct PhysicsMaterial {
    var density: Float        ///< The density of the object.
    var elasticity: Float     ///< The bounciness of the physics body.
    var friction: Float       ///< The roughness of the surface of a shape.
    
    public static let `default` = PhysicsMaterial(density: 0.1, elasticity: 0.5, friction: 0.5)
}

/**
 * @brief A shape for body. You do not create PhysicsShape objects directly, instead, you can view PhysicsBody to see how to create it.
 */
public class PhysicsShape: Tagged {
    
    public var tag: Int = 0
    
    /**
     * Get the body that this shape attaches.
     *
     * @return A PhysicsBody object pointer.
     */
    internal(set) weak public var body: PhysicsBody? {
        didSet {
            for cps in chipmunkShapes {
                cpShapeSetBody(cps, body?.chipmunkBody ?? SHARED_BODY)
            }
        }
    }
    
    /**
     * Return this shape's type.
     *
     * @return A Type object.
     */
    internal(set) public var type: PhysicsShapeType = .unknown
    
    /**
     * Return this shape's area.
     *
     * @return A float number.
     */
    internal(set) public var area: Float = 0.0
    
    // MARK: Physics properties 
    /**
     * This shape's moment.
     *
     * It will change the body's moment this shape attaches.
     *
     * @param moment A float number.
     */
    public var moment: Float = 0.0 {
        didSet {
            guard moment >= 0.0 else {
                return
            }
            
            if let body = self.body {
                body.add(moment: -oldValue)
                body.add(moment: moment)
            }
        }
    }
    
    /**
     * This shape's mass.
     *
     * It will change the body's mass this shape attaches.
     *
     * @param mass A float number.
     */
    public var mass: Float = 0.0 {
        didSet {
            guard moment >= 0.0 else {
                return
            }
            
            if let body = self.body {
                body.add(mass: -oldValue)
                body.add(mass: mass)
            }
        }
    }
    
    // MARK: Material
    /**
     * Get this shape's PhysicsMaterial object.
     *
     * @return A PhysicsMaterial object reference.
     */
    public var material: PhysicsMaterial {
        get {
            return _material
        }
        set {
            self.density = newValue.density
            self.elasticity = newValue.elasticity
            self.friction = newValue.friction
        }
    }
    
    /**
     * This shape's density.
     *
     * It will change the body's mass this shape attaches.
     *
     * @param density A float number.
     */
    public var density: Float {
        get { return _material.density }
        set {
            guard newValue >= 0.0 else {
                return
            }
            
            _material.density = newValue
            
            if newValue == Float.infinity {
                mass = Float.infinity
            } else {
                mass = newValue * area
            }
        }
    }
    
    /**
     * This shape's elasticity.
     *
     * It will change the shape's elasticity.
     *
     * @param restitution A float number.
     */
    public var elasticity: Float {
        get { return _material.elasticity }
        set {
            _material.elasticity = newValue
            
            for cps in chipmunkShapes {
                cpShapeSetElasticity(cps, cpFloat(newValue))
            }
        }
    }
    
    /**
     * This shape's friction.
     *
     * It will change the shape's friction.
     *
     * @param friction A float number.
     */
    public var friction: Float {
        get { return _material.friction }
        set {
            _material.friction = newValue
            
            for cps in chipmunkShapes {
                cpShapeSetFriction(cps, cpFloat(newValue))
            }
        }
    }
    
    // MARK: Interaction properties
    /**
     * Set the group of body.
     *
     * Collision groups let you specify an integral group index. You can have all fixtures with the same group index always collide (positive index) or never collide (negative index).
     * @param group An integer number, it have high priority than bit masks.
     */
    public var group: Int = 0 {
        didSet {
            if group < 0 {
                for shape in chipmunkShapes {
                    cpShapeSetFilter(shape, cpShapeFilterNew(cpGroup(group), CP_ALL_CATEGORIES, CP_ALL_CATEGORIES))
                }
            }
        }
    }
    
    /**
     * Get this shape's position offset.
     *
     * This function should be overridden in inherit classes.
     * @return A Vec2 object.
     */
    public var offset: Vector2f { return Vector2f.zero }
    
    /**
     * Get this shape's center position.
     *
     * This function should be overridden in inherit classes.
     * @return A Vec2 object.
     */
    public var center: Vector2f { return offset }
    
    /**
     * A mask that defines which categories of physics bodies can collide with this physics body.
     *
     * When two physics bodies contact each other, a collision may occur. This body's collision mask is compared to the other body's category mask by performing a logical AND operation. If the result is a non-zero value, then this body is affected by the collision. Each body independently chooses whether it wants to be affected by the other body. For example, you might use this to avoid collision calculations that would make negligible changes to a body's velocity.
     * @param bitmask An integer number, the default value is 0xFFFFFFFF (all bits set).
     */
    public var collisionBitmask = UInt32.max
    
    /**
     * A mask that defines which categories of bodies cause intersection notifications with this physics body.
     *
     * When two bodies share the same space, each body's category mask is tested against the other body's contact mask by performing a logical AND operation. If either comparison results in a non-zero value, an PhysicsContact object is created and passed to the physics world’s delegate. For best performance, only set bits in the contacts mask for interactions you are interested in.
     * @param bitmask An integer number, the default value is 0x00000000 (all bits cleared).
     */
    public var contactTestBitmask = UInt32(0)
    
    /**
     * Set a mask that defines which categories this physics body belongs to.
     *
     * Every physics body in a scene can be assigned to up to 32 different categories, each corresponding to a bit in the bit mask. You define the mask values used in your game. In conjunction with the collisionBitMask and contactTestBitMask properties, you define which physics bodies interact with each other and when your game is notified of these interactions.
     * @param bitmask An integer number, the default value is 0xFFFFFFFF (all bits set).
     */
    public var categoryBitmask = UInt32.max
    
    public var isSensor: Bool = false {
        didSet {
            if isSensor != oldValue {
                for cps in chipmunkShapes {
                    cpShapeSetSensor(cps, isSensor ? 1 : 0)
                }
            }
        }
    }
    
    // Override me in subclasses
    open func calculateArea() -> Float {
        return 0.0
    }
    
    /**
     * Calculate the default moment value.
     *
     * This function should be overridden in inherit classes.
     * @return A float number, equals 0.0.
     */
    open func calculateDefaultMoment() -> Float { return 0.0 }
    
    // MARK: Internal vars
    internal var chipmunkShapes = [UnsafeMutablePointer<cpShape>]()
    internal var _material = PhysicsMaterial.default
    // MARK: Private vars
}
