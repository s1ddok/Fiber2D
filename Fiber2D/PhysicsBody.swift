//
//  PhysicsBody.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 18.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public class PhysicsBody: Behaviour {
    
    internal var chipmunkBody: UnsafeMutablePointer<cpBody>!
    internal(set) public var shapes = [PhysicsShape]()
    
    
    internal(set) public var joints = [PhysicsJoint]()
    
    
    public weak var world: PhysicsWorld? = nil
    
    public func remove(joint: PhysicsJoint) {
        
    }
    
    /**
     * @brief Remove a shape from body.
     * @param shape Shape the shape to be removed.
     * @param reduceMassAndMoment If this is true, the body mass and moment will be reduced by shape. The default is true.
     */
    func remove(shape: PhysicsShape, reduceMassAndMoment: Bool = true) {
        
    }
}

extension PhysicsBody {
    /** remove the body from the world it added to */
    func removeFromWorld() {}
}
