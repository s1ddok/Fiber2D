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
    public func removeBody(by tag: Int) {
        if let body = bodies.first(where: { $0.tag == tag }) {
            remove(body: body)
        }
    }
    
    /**
     * Remove a body from this physics world.
     *
     * If this world is not locked, the body is removed immediately, otherwise at next frame.
     * @attention If this body has joints, those joints will be removed also.
     * @param   body   A pointer to an existing PhysicsBody object.
     */
    public func remove(body: PhysicsBody) {
        guard body.world === self else {
            print("Physics Warning: this body doesn't belong to this world")
            return
        }
        
        body.joints.forEach {
            self.remove(joint: $0)
        }
        body.joints.removeAll()
        
        removeBodyOrDelay(body: body)
        bodies.removeObject(body)
        body.world = nil
    }
    
    /**
     * Remove all bodies from physics world.
     *
     * If this world is not locked, those body are removed immediately, otherwise at next frame.
     */
    public func removeAllBodies() {
    
        for b in bodies {
            removeBodyOrDelay(body: b)
            b.world = nil
        }
        bodies.removeAll()
    }
}

internal extension PhysicsWorld {
    internal func add(body: PhysicsBody) {
        guard body.world !== self else {
            return
        }
        
        if let _ = body.world {
            body.removeFromPhysicsWorld()
        }
        
        addBodyOrDelay(body: body)
        bodies.append(body)
        body.world = self
    }
    
    internal func updateBodies() {
        guard cpSpaceIsLocked(chipmunkSpace) == 0 else {
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
    
    internal func addBodyOrDelay(body: PhysicsBody) {
        guard !(delayRemoveBodies.contains { $0 === body }) else {
            delayRemoveBodies.removeObject(body)
            return
        }
        
        if !delayAddBodies.contains { $0 === body } {
            delayAddBodies.append(body)
        }
    }
    
    internal func removeBodyOrDelay(body: PhysicsBody) {
        if delayAddBodies.contains(where: { $0 === body }) {
            delayAddBodies.removeObject(body)
        }
        
        if cpSpaceIsLocked(chipmunkSpace) != 0 {
            doRemove(body: body)
        } else {
            if !delayRemoveBodies.contains { $0 === body } {
                delayRemoveBodies.append(body)
            }
        }
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
