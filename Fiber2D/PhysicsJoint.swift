//
//  PhysicsJoint.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 18.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/**
 * @brief An PhysicsJoint object connects two physics bodies together.
 */
public class PhysicsJoint: Tagged {
    /**
     * Get this joint's tag.
     *
     * @return An integer number.
     */
    public var tag: Int = 0
    
    /**Get the physics world.*/
    internal(set) weak public var world: PhysicsWorld?
    /**Get physics body a connected to this joint.*/
    internal(set) weak public var bodyA: PhysicsBody?
    /**Get physics body a connected to this joint.*/
    internal(set) weak public var bodyB: PhysicsBody?
    
    /** Determines if the collision is enabled. */
    public var collisionEnabled = true
    /** Determines if the joint is enable. */
    public var enabled = true {
        didSet {
            guard let world = self.world else {
                return
            }
            
            if enabled != oldValue {
                if enabled {
                    world.add(joint: self)
                } else {
                    world.remove(joint: self)
                }
            }
        }
    }
    
    /** Set the max force between two bodies. */
    public var maxForce = Float.infinity {
        didSet {
            for cpc in chipmunkConstraints {
                cpConstraintSetMaxForce(cpc, cpFloat(maxForce))
            }
        }
    }
    
    init(bodyA: PhysicsBody, bodyB: PhysicsBody) {
        guard bodyA !== bodyB else {
            fatalError("Bodies can't be joined to itself")
        }
        
        self.bodyA = bodyA
        self.bodyB = bodyB
        
        bodyA.joints.append(self)
        bodyB.joints.append(self)
    }
    // MARK: Internal vars
    private var chipmunkInitialized = false
    internal var chipmunkConstraints = [UnsafeMutablePointer<cpConstraint>]()
    internal func createConstraints() {}
    internal func chipmunkInitJoint() -> Bool {
        guard !chipmunkInitialized else {
            return chipmunkInitialized
        }
        createConstraints()
        
        for subjoint in chipmunkConstraints {
            cpConstraintSetMaxForce(subjoint, cpFloat(maxForce));
            cpConstraintSetErrorBias(subjoint, cpFloat(pow(1.0 - 0.15, 60.0)));
            cpSpaceAddConstraint(world!.chipmunkSpace, subjoint);
        }
        
        chipmunkInitialized = true
        
        return chipmunkInitialized
    }
    
    deinit {
        collisionEnabled = false
        
        for cpc in chipmunkConstraints {
            cpConstraintFree(cpc)
        }
    }
}

public extension PhysicsJoint {
    /** Remove the joint from the world. */
    public func removeFormWorld() { world?.remove(joint: self) }
    
}
