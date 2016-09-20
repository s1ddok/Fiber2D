//
//  PhysicsWorld+Bodies.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 20.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public extension PhysicsWorld {
    /**
     * Get a body by tag.
     *
     * @param   tag   An integer number that identifies a PhysicsBody object.
     * @return A PhysicsBody object pointer or nullptr if no shapes were found.
     */
    public func getBody(by tag: Int) -> PhysicsBody? {
        return bodies.first {
            $0.tag == tag
        }
    }
    
    /**
     * Remove body by tag.
     *
     * If this world is not locked, the object is removed immediately, otherwise at next frame.
     * @attention If this body has joints, those joints will be removed also.
     * @param   tag   An integer number that identifies a PhysicsBody object.
     */
    public func removeBody(by tag: Int) {}
    
    /**
     * Remove all bodies from physics world.
     *
     * If this world is not locked, those body are removed immediately, otherwise at next frame.
     */
    public func removeAllBodies() {}
}

internal extension PhysicsWorld {
    internal func updateBodies() {
        guard cpSpaceIsLocked(chipmunkSpace) != 0 else {
            return
        }
        
        delayAddBodies.forEach {
            doAdd(body: $0)
        }
        delayAddBodies.removeAll()
        
        delayRemoveBodies.forEach {
            doRemove(body: $0)
        }
        delayRemoveBodies.removeAll()
    }
    
    internal func doAdd(body: PhysicsBody) {
        guard body.enabled else {
            return
        }
        
        if cpSpaceContainsBody(chipmunkSpace, body.chipmunkBody) == 0 {
            cpSpaceAddBody(chipmunkSpace, body.chipmunkBody)
        }
        
        for shape in body.shapes {
            add(shape: shape)
        }
    }
    
    internal func doRemove(body: PhysicsBody) {
        // remove shapes
        for shape in body.shapes {
            remove(shape: shape)
        }
        
        // remove body
        if cpSpaceContainsBody(chipmunkSpace, body.chipmunkBody) != 0 {
            cpSpaceRemoveBody(chipmunkSpace, body.chipmunkBody)
        }
    }
}
