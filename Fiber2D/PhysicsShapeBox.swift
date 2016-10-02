//
//  PhysicsShapeBox.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 22.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

public class PhysicsShapeBox: PhysicsShapePolygon {
    /**
     * Get this box's width and height.
     *
     * @return An Size object.
     */
    public var size: Size {
        let shape = chipmunkShapes.first!
        return Size(cpv(cpvdist(cpPolyShapeGetVert(shape, 1), cpPolyShapeGetVert(shape, 2)),
                        cpvdist(cpPolyShapeGetVert(shape, 0), cpPolyShapeGetVert(shape, 1))))
    }
    
    /**
     * Creates a PhysicsShapeBox with specified value.
     *
     * @param   size Size contains this box's width and height.
     * @param   material A PhysicsMaterial object, the default value is PHYSICSSHAPE_MATERIAL_DEFAULT.
     * @param   offset A Vec2 object, it is the offset from the body's center of gravity in body local coordinates.
     * @return  An autoreleased PhysicsShapeBox object pointer.
     */
    init(size: Size, material: PhysicsMaterial = PhysicsMaterial.default, offset: Vector2f = Vector2f.zero, radius: Float = 0.0) {
        let wh = size
        let verts = [p2d(x: -wh.x/2.0, y: -wh.y/2.0),
                     p2d(x: -wh.x/2.0, y: wh.y/2.0),
                     p2d(x: wh.x/2.0, y: wh.y/2.0),
                     p2d(x: wh.x/2.0, y: -wh.y/2.0)]
        
        super.init(points: verts, material: material, offset: offset, radius: radius)

    }
}
