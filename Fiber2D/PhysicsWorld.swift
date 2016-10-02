//
//  PhysicsWorld.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 18.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

/**
 * @class PhysicsWorld
 * @brief An PhysicsWorld object simulates collisions and other physical properties.
 */
public class PhysicsWorld {
    
    /** A delegate that is called when two physics shapes come in contact with each other. */
    public weak var contactDelegate: PhysicsContactDelegate?
    
    /**
     * Get the gravity value of this physics world.
     *
     * @return A Vec2 object.
     */
    public var gravity: vec2 = vec2(0.0, -98.0) {
        didSet {
            cpSpaceSetGravity(chipmunkSpace, cpVect(gravity))
        }
    }
    
    /**
     * Set the speed of this physics world.
     *
     * @attention if you set autoStep == false, this won't work.
     * @param speed  A float number. Speed is the rate at which the simulation executes. default value is 1.0.
     */
    public var speed: Float = 1.0
    
    /**
     * The number of substeps in an update of the physics world.
     *
     * One physics update will be divided into several substeps to increase its accuracy.
     * @param steps An integer number, default value is 1.
     */
    public var substeps: UInt = 1 {
        didSet {
            if substeps > 1 {
                updateRate = 1
            }
        }
    }
    
    /**
     * Set the update rate of this physics world
     *
     * Update rate is the value of EngineUpdateTimes/PhysicsWorldUpdateTimes.
     * Set it higher can improve performance, set it lower can improve accuracy of physics world simulation.
     * @attention if you set autoStep == false, this won't work.
     * @param rate An float number, default value is 1.0.
     */
    public var updateRate: Float = 1.0
    
    /**
     * set the number of update of the physics world in a second.
     * 0 - disable fixed step system
     * default value is 0
     */
    public var fixedUpdateRate: UInt = 0
    
    /**
     * The debug draw options of this physics world.
     *
     * This physics world will draw shapes and joints by DrawNode according to mask.
     */
    public var debugDrawOptions = [DebugDrawOption]()
    
    /**
     * To control the step of physics.
     *
     * If you want control it by yourself( fixed-timestep for example ), you can set this to false and call step by yourself.
     * @attention If you set auto step to false, setSpeed setSubsteps and setUpdateRate won't work, you need to control the time step by yourself.
     * @param autoStep A bool object, default value is true.
     */
    public var autoStep: Bool = true
    
    /**
     * The step for physics world.
     *
     * The times passing for simulate the physics.
     * @attention You need to setAutoStep(false) first before it can work.
     * @param   delta   A Time number.
     */
    public func step(dt: Time) {
        guard !autoStep else {
            print("Cant step: You need to close auto step( autoStep = false ) first")
            return
        }
        
        updateDelaysIfNeeded()
        update(dt: dt, userCall: true)
    }

    /**
     * A root node that contains this physics world.
     *
     * @attention This value is initialized in constructor
     * @return A Node object reference.
     */
    public let rootNode: Node
    
    internal(set) public var joints = [PhysicsJoint]()
    
    /**
     * Get all the bodies that in this physics world.
     *
     * @return A [PhysicsBody] that contains all bodies in this physics world.
     */
    internal(set) public var bodies = [PhysicsBody]()
    
    public init(rootNode: Node) {
        self.rootNode = rootNode
        chipmunkSpace = cpHastySpaceNew()
        cpHastySpaceSetThreads(chipmunkSpace, 0)
        
        cpSpaceSetGravity(chipmunkSpace, cpVect(gravity))
        
        let handler = cpSpaceAddDefaultCollisionHandler(chipmunkSpace)!
        handler.pointee.userData = Unmanaged.passRetained(self).toOpaque()
        handler.pointee.beginFunc = collisionBeginCallbackFunc
        handler.pointee.postSolveFunc = collisionPostSolveCallbackFunc
        handler.pointee.preSolveFunc = collisionPreSolveCallbackFunc
        handler.pointee.separateFunc = collisionSeparateCallbackFunc
    }
    
    // MARK: Internal stuff
    // MARK: Chipmunk vars
    internal var chipmunkSpace: UnsafeMutablePointer<cpSpace>!
    
    // MARK: Joints vars
    internal var delayRemoveJoints = [PhysicsJoint]()
    internal var delayAddJoints = [PhysicsJoint]()
    // MARK: Bodies vars
    internal var delayRemoveBodies = [PhysicsBody]()
    internal var delayAddBodies = [PhysicsBody]()
    
    // MARK: Other vars
    internal var updateTime: Time = 0.0
    internal var updateRateCount = 0
    // MARK: Destructor
    deinit {
        cpHastySpaceFree(chipmunkSpace)
    }
}
