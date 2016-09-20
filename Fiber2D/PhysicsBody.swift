//
//  PhysicsBody.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 18.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/**
 * A body affect by physics.
 *
 * It can attach one or more shapes.
 * If you create body with createXXX, it will automatically compute mass and moment with density your specified(which is PHYSICSBODY_MATERIAL_DEFAULT by default, and the density value is 0.1f), and it based on the formula: mass = density * area.
 * If you create body with createEdgeXXX, the mass and moment will be inifinity by default. And it's a static body.
 * You can change mass and moment with `mass` and `moment`. And you can change the body to be dynamic or static by use `dynamic`.
 */
public class PhysicsBody: Behaviour {
    /**
     * @brief Test the body is dynamic or not.
     *
     * A dynamic body will effect with gravity.
     */
    public var isDynamic = false {
        didSet {
            guard isDynamic != oldValue else {
                return
            }
            
            if isDynamic {
                cpBodySetType(chipmunkBody, CP_BODY_TYPE_DYNAMIC)
                internalBodySetMass(chipmunkBody, cpFloat(_mass))
                cpBodySetMoment(chipmunkBody, cpFloat(_moment))
            } else {
                cpBodySetType(chipmunkBody, CP_BODY_TYPE_KINEMATIC);
            }
        }
    }
    
    /** if the body is affected by the physics world's gravitational force or not. */
    public var isGravityEnabled = false
    /** Whether the body can be rotated. */
    public var isRotationEnabled = false {
        didSet {
            if isRotationEnabled != oldValue {
                cpBodySetMoment(chipmunkBody, isRotationEnabled ? cpFloat(_moment) : cpFloat.infinity)
            }
        }
    }
    
    /** set body rotation offset, it's the rotation witch relative to node */
    public var rotationOffset: Angle {
        get { return _rotationOffset }
        set {
            if abs((_rotationOffset - newValue).degrees) > 0.5 {
                let rot = rotation
                _rotationOffset = newValue
                rotation = rot
            }
        }
    }
    
    /** get the body rotation. */
    public var rotation: Angle {
        get {
            let cpAngle = Angle(cpBodyGetAngle(chipmunkBody))
            
            if cpAngle != _recordedAngle {
                _recordedAngle = cpAngle
                _recordedRotation = -_recordedAngle - rotationOffset
            }
            
            return _recordedRotation
        }
        set {
            _recordedRotation = newValue
            _recordedAngle = -rotation - rotationOffset
            cpBodySetAngle(chipmunkBody, cpFloat(_recordedAngle.radians))
        }
    }
    
    /**
     * The velocity of a body.
     */
    public var velocity: Vector2f {
        get { return Vector2f(cpBodyGetVelocity(chipmunkBody)) }
        set {
            guard isDynamic else {
                print("physics warning: your can't set velocity for a static body.")
                return
            }
            
            cpBodySetVelocity(chipmunkBody, cpVect(velocity))
        }
    }
    
    /** The max of velocity */
    public var velocityLimit: Float = Float.infinity
    
    /**
     * The angular velocity of a body.
     */
    public var angularVelocity: Float = 0.0
    
    /** The max of angular velocity */
    public var angularVelocityLimit: Float = Float.infinity
 
    internal(set) public var shapes = [PhysicsShape]()
    
    internal(set) public var joints = [PhysicsJoint]()
    
    /** get the world body added to. */
    internal(set) public weak var world: PhysicsWorld? = nil
    
    override init() {
        chipmunkBody = cpBodyNew(cpFloat(_mass), cpFloat(_moment))
        super.init()
        internalBodySetMass(chipmunkBody, cpFloat(_mass))
        cpBodySetUserData(chipmunkBody, Unmanaged.passRetained(self).toOpaque())
        cpBodySetVelocityUpdateFunc(chipmunkBody, internalBodyUpdateVelocity)
    }
    
    // MARK: Component stuff
    public override func onEnter() {
        addToPhysicsWorld()
    }
    public override func onExit() {
        removeFromPhysicsWorld()
    }
    public override func onAdd() {
        let contentSize = owner!.contentSize
        ownerCenterOffset = contentSize * 0.5
        
        rotationOffset = owner!.rotation
        // component may be added after onEnter() has been invoked, so we should add
        // this line to make sure physics body is added to physics world
        addToPhysicsWorld();
    }
    public override func onRemove() {
        removeFromPhysicsWorld()
    }
    
    // MARK: Internal vars
    /** The rigid body of chipmunk. */
    internal let chipmunkBody: UnsafeMutablePointer<cpBody>
    // offset between owner's center point and down left point
    internal var ownerCenterOffset = Vector2f.zero
    
    // it means body's moment is not calculated by shapes
    internal var _momentSetByUser = false
    internal var _momentDefault   = true
    internal var _moment: Float = 0.0
    // it means body's mass is not calculated by shapes
    internal var _massSetByUser = false
    internal var _massDefault = true
    internal var _mass: Float = 0.0
    
    internal var _density: Float = 0.0
    internal var _area: Float = 0.0
    // MARK: Private vars
    private var _rotationOffset: Angle = 0°
    private var _recordedAngle: Angle = 0°
    private var _recordedRotation: Angle = 0°
}

extension PhysicsBody {
    func addToPhysicsWorld() { owner?.scene?.physicsWorld.remove(body: self) }
    /** remove the body from the world it added to */
    func removeFromPhysicsWorld() { owner?.scene?.physicsWorld.remove(body: self) }
}
