//
//  PhysicsWorld+Joints.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 20.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public extension PhysicsWorld {
    /**
     * Adds a joint to this physics world.
     *
     * This joint will be added to this physics world at next frame.
     * @attention If this joint is already added to another physics world, it will be removed from that world first and then add to this world.
     * @param   joint   A pointer to an existing PhysicsJoint object.
     */
    public func add(joint: PhysicsJoint) {
        guard joint.world == nil else {
            fatalError("Can not add joint already added to other world!")
        }
        
        joint.world = self
        
        if let idx = delayRemoveJoints.index(where: { $0 === joint } ) {
            delayRemoveJoints.remove(at: idx)
            return
        }
        
        if delayAddJoints.index(where: { $0 === joint } ) == nil {
            delayAddJoints.append(joint)
        }
    }
    
    /**
     * Remove a joint from this physics world.
     *
     * If this world is not locked, the joint is removed immediately, otherwise at next frame.
     * If this joint is connected with a body, it will be removed from the body also.
     * @param   joint   A pointer to an existing PhysicsJoint object.
     */
    public func remove(joint: PhysicsJoint) {
        guard joint.world === self else {
            print("Joint is not in this world")
            return
        }
        
        let idx = delayAddJoints.index {
            $0 === joint
        }
        
        let removedFromDelayAdd = idx != nil
        if removedFromDelayAdd {
            delayAddJoints.remove(at: idx!)
        }
        
        if cpSpaceIsLocked(chipmunkSpace) != 0 {
            guard !removedFromDelayAdd else {
                return
            }
            
            if !delayRemoveJoints.contains { $0 === joint } {
                delayRemoveJoints.append(joint)
            }
            
        } else {
            doRemove(joint: joint)
        }
    }
    
    /**
     * Remove all joints from this physics world.
     *
     * @attention This function is invoked in the destructor of this physics world, you do not use this api in common.
     */
    public func removeAllJoints() {
        for joint in joints {
            remove(joint: joint)
        }
    }
}

internal extension PhysicsWorld {
    internal func updateJoints() {
        guard cpSpaceIsLocked(chipmunkSpace) != 0 else {
            return
        }
        
        for joint in delayAddJoints {
            if joint.chipmunkInitJoint() {
                joints.append(joint)
            }
        }
        delayAddJoints.removeAll()
        
        for joint in delayRemoveJoints {
            doRemove(joint: joint)
        }
        delayRemoveJoints.removeAll()
    }
    
    internal func doRemove(joint: PhysicsJoint) {
        for constraint in joint.chipmunkConstraints {
            cpSpaceRemoveConstraint(chipmunkSpace, constraint)
        }
        
        joints.removeObject(joint)
        joint.world = nil
        
        if let ba = joint.bodyA {
            ba.remove(joint: joint)
        }
        
        if let bb = joint.bodyB {
            bb.remove(joint: joint)
        }
        
    }
}
