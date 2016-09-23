//
//  PhysicsBody+Shapes.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 20.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

extension PhysicsBody {
    // MARK: Shapes
    /**
     * get the shape of the body.
     *
     * @param   tag   An integer number that identifies a PhysicsShape object.
     * @return A PhysicsShape object pointer or nullptr if no shapes were found.
     */
    func getShape(by tag: Int) -> PhysicsShape? {
        return shapes.first(where: { (shape:PhysicsShape) -> Bool in
            shape.tag == tag
        })
    }
    /**
     * @brief Add a shape to body.
     * @param shape The shape to be added.
     * @param addMassAndMoment If this is true, the shape's mass and moment will be added to body. The default is true.
     * @return This shape's pointer if added success or nullptr if failed.
     */
    func add(shape: PhysicsShape, addMassAndMoment: Bool = true) {
        guard !shapes.contains(where: { (s: PhysicsShape) -> Bool in
            s === shape
        }) else { return }
        
        shape.body = self
        
        // calculate the area, mass, and density
        // area must update before mass, because the density changes depend on it.
        if addMassAndMoment {
            _area += shape.area
            add(mass: shape.mass)
            add(moment: shape.moment)
        }
        
        if cpBodyGetSpace(chipmunkBody) != nil {
            world?.add(shape: shape)
        }
        
        shapes.append(shape)
    }
    
    /**
     * @brief Remove a shape from body.
     * @param shape Shape the shape to be removed.
     * @param reduceMassAndMoment If this is true, the body mass and moment will be reduced by shape. The default is true.
     */
    func remove(shape: PhysicsShape, reduceMassAndMoment: Bool = true) {
        if reduceMassAndMoment {
            _area -= shape.area
            add(mass: -shape.mass)
            add(moment: -shape.moment)
        }
        
        world?.remove(shape: shape)
        
        shape.body = nil
        shapes.removeObject(shape)
    }
    
    /**
     * @brief Remove a shape from body.
     * @param tag The tag of the shape to be removed.
     * @param reduceMassAndMoment If this is true, the body mass and moment will be reduced by shape. The default is true.
     */
    func removeShape(by tag: Int, reduceMassAndMoment: Bool = true) {
        if let found = shapes.first(where: { $0.tag == tag }) {
            remove(shape: found, reduceMassAndMoment: reduceMassAndMoment)
        }
    }
    
    /**
     * Remove all shapes.
     *
     * @param reduceMassAndMoment If this is true, the body mass and moment will be reduced by shape. The default is true.
     */
    func removeAllShapes(reduceMassAndMoment: Bool = true) {
        for shape in shapes {
            if reduceMassAndMoment {
                _area -= shape.area
                add(mass: -shape.mass)
                add(moment: -shape.moment)
            }
            
            world?.remove(shape: shape)
            
            shape.body = nil
        }
        shapes.removeAll()
    }
}

public extension PhysicsBody {
    /**
     * A mask that defines which categories of physics bodies can collide with this physics body.
     *
     * When two physics bodies contact each other, a collision may occur. This body's collision mask is compared to the other body's category mask by performing a logical AND operation. If the result is a non-zero value, then this body is affected by the collision. Each body independently chooses whether it wants to be affected by the other body. For example, you might use this to avoid collision calculations that would make negligible changes to a body's velocity.
     * @param bitmask An integer number, the default value is 0xFFFFFFFF (all bits set).
     */
    public var collisionBitmask: UInt32 {
        get {
            if let first = shapes.first {
                return first.collisionBitmask
            }
            return UInt32.max
        }
        set {
            for shape in shapes {
                shape.collisionBitmask = newValue
            }
        }
    }
    
    /**
     * A mask that defines which categories of bodies cause intersection notifications with this physics body.
     *
     * When two bodies share the same space, each body's category mask is tested against the other body's contact mask by performing a logical AND operation. If either comparison results in a non-zero value, an PhysicsContact object is created and passed to the physics world’s delegate. For best performance, only set bits in the contacts mask for interactions you are interested in.
     * @param bitmask An integer number, the default value is 0x00000000 (all bits cleared).
     */
    public var contactTestBitmask: UInt32 {
        get {
            if let first = shapes.first {
                return first.contactTestBitmask
            }
            return 0x00000000
        }
        set {
            for shape in shapes {
                shape.contactTestBitmask = newValue
            }
        }
    }
    
    /**
     * Set a mask that defines which categories this physics body belongs to.
     *
     * Every physics body in a scene can be assigned to up to 32 different categories, each corresponding to a bit in the bit mask. You define the mask values used in your game. In conjunction with the collisionBitMask and contactTestBitMask properties, you define which physics bodies interact with each other and when your game is notified of these interactions.
     * @param bitmask An integer number, the default value is 0xFFFFFFFF (all bits set).
     */
    public var categoryBitmask: UInt32 {
        get {
            if let first = shapes.first {
                return first.categoryBitmask
            }
            return UInt32.max
        }
        set {
            for shape in shapes {
                shape.categoryBitmask = newValue
            }
        }
    }
    
    /**
     * Return group of first shape.
     *
     * @return If there is no shape in body, return default value.(0)
     */
    public var group: Int {
        get {
            if let first = shapes.first {
                return first.group
            }
            
            return 0
        }
        set {
            for shape in shapes {
                shape.group = newValue
            }
        }
    }
}
