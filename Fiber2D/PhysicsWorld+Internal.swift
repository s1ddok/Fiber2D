//
//  PhysicsWorld+Internal.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 18.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

internal func collisionBeginCallbackFunc(_ arb: UnsafeMutablePointer<cpArbiter>?, _ space: UnsafeMutablePointer<cpSpace>?, _ world: cpDataPointer?) -> cpBool {
    
    var a: UnsafeMutablePointer<cpShape>? = nil
    var b: UnsafeMutablePointer<cpShape>? = nil
    cpArbiterGetShapes(arb, &a, &b)
    
    let shapeA = Unmanaged<PhysicsShape>.fromOpaque(cpShapeGetUserData(a)).takeUnretainedValue()
    let shapeB = Unmanaged<PhysicsShape>.fromOpaque(cpShapeGetUserData(b)).takeUnretainedValue()
    
    let contactPointer = UnsafeMutablePointer<PhysicsContact>.allocate(capacity: 1)
    let contact = PhysicsContact(shapeA: shapeA, shapeB: shapeB, arb: arb)
    contactPointer.initialize(to: contact)
    cpArbiterSetUserData(arb, contactPointer)
    
    let world = Unmanaged<PhysicsWorld>.fromOpaque(world!).takeUnretainedValue()
    world.contactDelegate?.didBegin(contact: contact)
    
    return 1
}

internal func collisionPreSolveCallbackFunc(_ arb: UnsafeMutablePointer<cpArbiter>?, _ space: UnsafeMutablePointer<cpSpace>?, _ world: cpDataPointer?) -> cpBool {
    return 1
}

internal func collisionPostSolveCallbackFunc(_ arb: UnsafeMutablePointer<cpArbiter>?, _ space: UnsafeMutablePointer<cpSpace>?, _ world: cpDataPointer?) -> Void {
}

internal func collisionSeparateCallbackFunc(_ arb: UnsafeMutablePointer<cpArbiter>?, _ space: UnsafeMutablePointer<cpSpace>?, _ world: cpDataPointer?) -> Void {
    let contactPointer = cpArbiterGetUserData(arb).assumingMemoryBound(to: PhysicsContact.self)
    let contact = contactPointer.pointee
    let world = Unmanaged<PhysicsWorld>.fromOpaque(world!).takeUnretainedValue()
    world.contactDelegate?.didEnd(contact: contact)
    free(contactPointer)
}

internal extension PhysicsWorld {
    
    internal func updateDelaysIfNeeded() {
        if !delayAddBodies.isEmpty || !delayRemoveBodies.isEmpty {
            updateBodies()
        }
        
        if !delayAddJoints.isEmpty || !delayRemoveJoints.isEmpty {
            updateJoints()
        }
    }
    
    internal func update(dt: Time, userCall: Bool = false) {
        guard dt > Float.ulpOfOne else {
            return
        }
        
        if userCall {
            cpHastySpaceStep(chipmunkSpace, cpFloat(dt))
        } else {
            updateTime += dt
            
            if fixedUpdateRate > 0 {
                let step = 1.0 / Time(fixedUpdateRate)
                let dt = step * speed
                while updateTime > step {
                    updateTime -= step
                    
                    cpHastySpaceStep(chipmunkSpace, cpFloat(dt))
                }
            } else {
                updateRateCount += 1
                if Float(updateRateCount) > updateRate {
                    let dt = updateTime * speed / Time(substeps)
                    for _ in 0..<substeps {
                        cpHastySpaceStep(chipmunkSpace, cpFloat(dt))
                        
                        for b in bodies {
                            b.fixedUpdate(delta: dt)
                        }
                    }
                    
                    updateRateCount = 0
                    updateTime = 0
                }
                
            }
        }
        
        // debugDraw()
    }

}
