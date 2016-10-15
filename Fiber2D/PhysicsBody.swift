//
//  PhysicsBody.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 18.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

/**
 * A body affect by physics.
 *
 * It can attach one or more shapes.
 * If you create body with createXXX, it will automatically compute mass and moment with density your specified(which is PHYSICSBODY_MATERIAL_DEFAULT by default, and the density value is 0.1f), and it based on the formula: mass = density * area.
 * If you create body with createEdgeXXX, the mass and moment will be inifinity by default. And it's a static body.
 * You can change mass and moment with `mass` and `moment`. And you can change the body to be dynamic or static by use `dynamic`.
 */
public class PhysicsBody: ComponentBase, Behaviour, FixedUpdatable, Pausable {
    // MARK: State
    /** Whether the body is at rest. */
    public var isResting: Bool {
        get {
            return cpBodyIsSleeping(chipmunkBody) == 0
        }
        set {
            let isResting = self.isResting
            if newValue && !isResting {
                cpBodySleep(chipmunkBody)
            } else if !newValue && isResting {
                cpBodyActivate(chipmunkBody)
            }
        }
    }
    /**
     * @brief Test the body is dynamic or not.
     *
     * A dynamic body will effect with gravity.
     */
    public var isDynamic = true {
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
    public var isRotationEnabled = true {
        didSet {
            if isRotationEnabled != oldValue {
                cpBodySetMoment(chipmunkBody, isRotationEnabled ? cpFloat(_moment) : cpFloat.infinity)
            }
        }
    }
    
    // MARK: Properties
    
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
            let cpAngle = Angle(radians: Float(cpBodyGetAngle(chipmunkBody)))
            
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
    
    /** get the body position. */
    public var position: Point {
        get {
            let tt = cpBodyGetPosition(chipmunkBody)
            
            return Point(tt) - positionOffset
        }
        set {
            cpBodySetPosition(chipmunkBody, cpVect(newValue + positionOffset))
        }
        
    }
    
    /** set body position offset, it's the position which is relative to the node */
    public var positionOffset: Vector2f {
        get {
            return _positionOffset
        }
        set {
            if _positionOffset != newValue {
                let pos = self.position
                _positionOffset = newValue
                self.position = pos
            }
        }
    }
    
    internal var scale: (x: Float, y: Float) = (x: 1.0, y: 1.0) {
        didSet {
            for shape in shapes {
                _area -= shape.area
                if !_massSetByUser {
                    add(mass: -shape.mass)
                }
                if !_momentSetByUser {
                    add(moment: -shape.moment)
                }
                
                // shape.scale = scale 
                
                _area += shape.area
                if !_massSetByUser {
                    add(mass: shape.mass)
                }
                if !_momentSetByUser {
                    add(moment: shape.moment)
                }
                
            }
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
    public var angularVelocity: Float {
        get {
            return Float(cpBodyGetAngularVelocity(chipmunkBody))
        }
        set {
            guard isDynamic else {
                print("You can't set angular velocity for a static body.")
                return
            }
            
            cpBodySetAngularVelocity(chipmunkBody, cpFloat(newValue))
        }
    }
    
    /** The max of angular velocity */
    public var angularVelocityLimit: Float = Float.infinity
    
    /**
     * Linear damping.
     *
     * it is used to simulate fluid or air friction forces on the body.
     * @param damping The value is 0.0f to 1.0f.
     */
    public var linearDamping: Float = 0.0 {
        didSet {
            updateDamping()
        }
    }
    
    /**
     * Angular damping.
     *
     * It is used to simulate fluid or air friction forces on the body.
     * @param damping The value is 0.0f to 1.0f.
     */
    public var angularDamping: Float = 0.0 {
        didSet {
            updateDamping()
        }
    }
    
    private func updateDamping() { _isDamping = linearDamping != 0.0 ||  angularDamping != 0.0 }
 
    internal(set) public var shapes = [PhysicsShape]()
    
    internal(set) public var joints = [PhysicsJoint]()
    
    /** get the world body added to. */
    internal(set) public weak var world: PhysicsWorld? = nil
    
    override init() {
        chipmunkBody = cpBodyNew(cpFloat(_mass), cpFloat(_moment))
        super.init()
        internalBodySetMass(chipmunkBody, cpFloat(_mass))
        cpBodySetUserData(chipmunkBody, Unmanaged.passUnretained(self).toOpaque())
        cpBodySetVelocityUpdateFunc(chipmunkBody, internalBodyUpdateVelocity)
    }
    
    public var paused: Bool = false
    public func fixedUpdate(delta: Time) {
        // damping compute
        if (_isDamping && isDynamic && !isResting) {
            chipmunkBody.pointee.v.x *= cpfclamp(1.0 - cpFloat(delta * linearDamping), 0.0, 1.0)
            chipmunkBody.pointee.v.y *= cpfclamp(1.0 - cpFloat(delta * linearDamping), 0.0, 1.0)
            chipmunkBody.pointee.w   *= cpfclamp(1.0 - cpFloat(delta * angularDamping), 0.0, 1.0)
        }
    }
    // MARK: Component stuff
    public var enabled: Bool = true {
        didSet {
            if oldValue != enabled {
                if enabled {
                    world?.addBodyOrDelay(body: self)
                    paused = false
                } else {
                    world?.removeBodyOrDelay(body: self)
                    paused = true
                }
            }
        }
    }
    
    public override func onAdd(to owner: Node) {
        super.onAdd(to: owner)
        let contentSize = owner.contentSizeInPoints
        ownerCenterOffset = contentSize * 0.5
        
        rotationOffset = owner.rotation
    }
    
    // MARK: Internal vars
    /** The rigid body of chipmunk. */
    internal let chipmunkBody: UnsafeMutablePointer<cpBody>
    // offset between owner's center point and down left point
    internal var ownerCenterOffset = Vector2f.zero
    
    // it means body's moment is not calculated by shapes
    internal var _momentSetByUser = false
    internal var _momentDefault   = true
    internal var _moment: Float = MOMENT_DEFAULT
    // it means body's mass is not calculated by shapes
    internal var _massSetByUser = false
    internal var _massDefault = true
    internal var _mass: Float = MASS_DEFAULT
    
    internal var _density: Float = 0.0
    internal var _area: Float = 0.0
    
    internal var _recordPos = Point.zero
    internal var _offset = Vector2f.zero
    internal var _isDamping = false
    
    internal var _recordScaleX: Float = 0.0
    internal var _recordScaleY: Float = 0.0
    
    internal var _recordedRotation: Angle = 0°
    // MARK: Private vars
    private var _rotationOffset: Angle = 0°
    private var _recordedAngle: Angle = 0°
    
    
    private var _positionOffset: Vector2f = Vector2f.zero
}

extension PhysicsBody {
    func addToPhysicsWorld() {
        if let physicsSystem = owner?.scene?.system(for: PhysicsSystem.self) {
            physicsSystem.world.add(body: self)
            physicsSystem.dirty = true
        }
    }
    
    /** remove the body from the world it added to */
    func removeFromPhysicsWorld() {
        if let physicsSystem = owner?.scene?.system(for: PhysicsSystem.self) {
            physicsSystem.world.remove(body: self)
            physicsSystem.dirty = true
        }
    }
}

public extension PhysicsBody {
    /**
     * Create a body contains a circle.
     *
     * @param   radius A float number, it is the circle's radius.
     * @param   material A PhysicsMaterial object, the default value is PHYSICSSHAPE_MATERIAL_DEFAULT.
     * @param   offset A Vec2 object, it is the offset from the body's center of gravity in body local coordinates.
     * @return  An autoreleased PhysicsBody object pointer.
     */
    public static func circle(radius: Float, material: PhysicsMaterial = PhysicsMaterial.default, offset: Vector2f = Vector2f.zero) -> PhysicsBody {
        let circleShape = PhysicsShapeCircle(radius: radius, material: material, offset: offset)
        let body = PhysicsBody()
        body.add(shape: circleShape)
        return body
    }
    
    /**
     * Create a body contains a box shape.
     *
     * @param   size Size contains this box's width and height.
     * @param   material A PhysicsMaterial object, the default value is PHYSICSSHAPE_MATERIAL_DEFAULT.
     * @param   offset A Vec2 object, it is the offset from the body's center of gravity in body local coordinates.
     * @return  An autoreleased PhysicsBody object pointer.
     */
    public static func box(size: Size, material: PhysicsMaterial = PhysicsMaterial.default, offset: Vector2f = Vector2f.zero) -> PhysicsBody {
        let boxShape = PhysicsShapeBox(size: size, material: material, offset: offset)
        let body = PhysicsBody()
        body.add(shape: boxShape)
        return body
    }
    
}

