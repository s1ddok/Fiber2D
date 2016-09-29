//
//  PhysicsShapeCircle.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 21.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

/** A circle shape. */
public class PhysicsShapeCircle: PhysicsShape {
    /**
     * Get the circle's radius.
     *
     * @return A float number.
     */
    public var radius: Float {
        return Float(cpCircleShapeGetRadius(chipmunkShapes.first!))
    }
    
    public override var offset: Vector2f {
        return vec2(cpCircleShapeGetOffset(chipmunkShapes.first!))
    }
    
    public override func calculateArea() -> Float {
        return Float(cpAreaForCircle(0, cpCircleShapeGetRadius(chipmunkShapes.first!)))
    }
    
    override public func calculateDefaultMoment() -> Float {
        let shape = chipmunkShapes.first!
        return mass == PHYSICS_INFINITY ? PHYSICS_INFINITY
            : Float(cpMomentForCircle(cpFloat(mass),
                                    0,
                                    cpCircleShapeGetRadius(shape),
                                    cpCircleShapeGetOffset(shape)))
    }
    
    /**
     * Creates a PhysicsShapeCircle with specified value.
     *
     * @param   radius A float number, it is the circle's radius.
     * @param   material A PhysicsMaterial object, the default value is PHYSICSSHAPE_MATERIAL_DEFAULT.
     * @param   offset A Vec2 object, it is the offset from the body's center of gravity in body local coordinates.
     * @return  An autoreleased PhysicsShapeCircle object pointer.
     */
    init(radius: Float = 1.0, material: PhysicsMaterial = PhysicsMaterial.default, offset: Vector2f = Vector2f.zero) {
        super.init()
        type = .circle
        let shape = cpCircleShapeNew(SHARED_BODY, cpFloat(radius), cpVect(offset))!
        cpShapeSetUserData(shape, Unmanaged.passUnretained(self).toOpaque())
        add(shape: shape)
        
        area = calculateArea()
        mass = _material.density == PHYSICS_INFINITY ? PHYSICS_INFINITY : material.density * area
        moment = calculateDefaultMoment()
        
        self.material = material
    }
    
}
