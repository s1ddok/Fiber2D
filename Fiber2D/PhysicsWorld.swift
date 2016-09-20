//
//  PhysicsWorld.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 18.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/**
 * @class PhysicsWorld
 * @brief An PhysicsWorld object simulates collisions and other physical properties. 
 * You do not create PhysicsWorld objects directly;
 * instead, you can get it from an Scene object.
 */
public class PhysicsWorld {
    /**
     * Get the gravity value of this physics world.
     *
     * @return A Vec2 object.
     */
    public var gravity: vec2 = vec2(0.0, -98.0)
    
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
    public var substeps: UInt = 1
    
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
    public func step(dt: Time) {}
    
    /**
     * Get a scene contain this physics world.
     *
     * @attention This value is initialized in constructor
     * @return A Scene object reference.
     */
    public let scene: Scene
    
    public init(scene: Scene) {
        self.scene = scene
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
    internal var chipmunkSpace: UnsafeMutablePointer<cpSpace>!
    
    deinit {
        cpHastySpaceFree(chipmunkSpace)
    }
}

public extension PhysicsWorld {
    /**
     * Get a body by tag.
     *
     * @param   tag   An integer number that identifies a PhysicsBody object.
     * @return A PhysicsBody object pointer or nullptr if no shapes were found.
     */
    public func getBody(by tag: Int) -> PhysicsBody? { return nil }
    
    /**
     * Get all the bodies that in this physics world.
     *
     * @return A [PhysicsBody] that contains all bodies in this physics world.
     */
    public var allBodies: [PhysicsBody] { return [] }
    
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

public extension PhysicsWorld {
    /**
     * Adds a joint to this physics world.
     *
     * This joint will be added to this physics world at next frame.
     * @attention If this joint is already added to another physics world, it will be removed from that world first and then add to this world.
     * @param   joint   A pointer to an existing PhysicsJoint object.
     */
    public func add(joint: PhysicsJoint) {}
    
    /**
     * Remove a joint from this physics world.
     *
     * If this world is not locked, the joint is removed immediately, otherwise at next frame.
     * If this joint is connected with a body, it will be removed from the body also.
     * @param   joint   A pointer to an existing PhysicsJoint object.
     */
    public func remove(joint: PhysicsJoint) {}
    
    /**
     * Remove all joints from this physics world.
     *
     * @attention This function is invoked in the destructor of this physics world, you do not use this api in common.
     */
    public func removeAllJoints() {}
}
