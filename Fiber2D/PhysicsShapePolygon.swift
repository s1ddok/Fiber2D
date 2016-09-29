//
//  PhysicsShapePolygon.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 22.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

public class PhysicsShapePolygon: PhysicsShape {
    /**
     * Creates a PhysicsShapePolygon with specified value.
     *
     * @param   points A [Point] object, it is an array of Point.
     * @param   material A PhysicsMaterial object, the default value is PHYSICSSHAPE_MATERIAL_DEFAULT.
     * @param   offset A Vec2 object, it is the offset from the body's center of gravity in body local coordinates.
     * @return  An PhysicsShapePolygon object pointer.
     */
    init(points: [Point], material: PhysicsMaterial = PhysicsMaterial.default, offset: Vector2f = Vector2f.zero, radius: Float = 0.0) {
        super.init()
        let transform = cpTransformTranslate(cpVect(offset))
        let verts = points.map { (vec: Vector2f) -> cpVect in
            return cpVect(vec)
        }
        let shape = cpPolyShapeNew(SHARED_BODY, Int32(points.count), verts, transform, cpFloat(radius))!
        
        cpShapeSetUserData(shape, Unmanaged.passUnretained(self).toOpaque())
        
        add(shape: shape)
        
        area = calculateArea()
        mass = material.density == PHYSICS_INFINITY ? PHYSICS_INFINITY : material.density * area
        moment = calculateDefaultMoment()
        
        self.material = material
    }
    
    internal var verts: [cpVect] {
        let shape = chipmunkShapes.first!
        let count = cpPolyShapeGetCount(shape)
        var verts = [cpVect](repeating: cpVect(), count: Int(count))
        for i in 0..<count {
            verts[Int(i)] = cpPolyShapeGetVert(shape, i)
        }
        return verts
    }
    
    public override func calculateArea() -> Float {
        let verts = self.verts
        let shape = chipmunkShapes.first!
        return Float(cpAreaForPoly(Int32(verts.count), verts, cpPolyShapeGetRadius(shape)))
    }
    
    public override func calculateDefaultMoment() -> Float {
        if mass == PHYSICS_INFINITY {
            return PHYSICS_INFINITY
        } else {
            let shape = chipmunkShapes.first!
            let verts = self.verts
            return Float(cpMomentForPoly(cpFloat(mass), Int32(verts.count), verts, cpvzero, cpPolyShapeGetRadius(shape)))
        }
    }
    
    public override var center: Vector2f {
        let verts = self.verts
        return Vector2f(cpCentroidForPoly(Int32(verts.count), verts))
    }
}
