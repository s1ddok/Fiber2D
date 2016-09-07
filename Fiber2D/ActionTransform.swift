//
//  ActionTransform.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 03.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/**
 This action rotates the target to the specified angle.
 The direction will be decided by the shortest route.
 
 @warning Rotate actions shouldn't be used to rotate nodes with a dynamic PhysicsBody unless the body has allowsRotation set to NO.
 Otherwise both the physics body and the action will alter the node's rotation property, overriding each other's changes.
 This leads to unpredictable behavior.
 */
struct ActionRotateTo: ActionModel {
    private let dstAngleX   : Angle
    private var startAngleX : Angle!
    private let dstAngleY   : Angle
    private var startAngleY : Angle!
    private let rotateX: Bool
    private let rotateY: Bool
    private let simple: Bool
    private var target: Node!
    
    private var diffAngleY  = Angle.zero
    private var diffAngleX  = Angle.zero
    
    init(angle: Angle) {
        self.init(angleX: angle, angleY: angle)
    }
    
    init(angleX aX: Angle? = nil, angleY aY: Angle? = nil) {
        self.dstAngleX = aX ?? Angle.zero
        self.dstAngleY = aY ?? Angle.zero
        rotateX = aX != nil
        rotateY = aY != nil
        simple = aX == aY
    }

    mutating func start(with target: AnyObject?) {
        let target = target as! Node
        self.target = target
        // Simple Rotation
        if simple {
            self.startAngleX = target.rotation
            self.startAngleY = target.rotation
            self.diffAngleX = dstAngleX - startAngleX
            self.diffAngleY = dstAngleY - startAngleY
            return
        }
        //Calculate X
        self.startAngleX = target.rotationalSkewX
        if startAngleX > Angle.zero {
            self.startAngleX = startAngleX % Angle.pi2
        }
        else {
            self.startAngleX = startAngleX % -Angle.pi2
        }
        self.diffAngleX = dstAngleX - startAngleX
        if diffAngleX > Angle.pi {
            self.diffAngleX -= Angle.pi2
        }
        if diffAngleX < -Angle.pi {
            self.diffAngleX += Angle.pi2
        }
        //Calculate Y: It's duplicated from calculating X since the rotation wrap should be the same
        self.startAngleY = target.rotationalSkewY
        if startAngleY > Angle.zero {
            self.startAngleY = startAngleY % Angle.pi2
        }
        else {
            self.startAngleY = startAngleY % -Angle.pi2
        }
        self.diffAngleY = dstAngleY - startAngleY
        if diffAngleY > Angle.pi {
            self.diffAngleY -= Angle.pi2
        }
        if diffAngleY < -Angle.pi {
            self.diffAngleY += Angle.pi2
        }
    }

    mutating func update(state: Float) {
        // added to support overriding setRotation only
        if startAngleX == startAngleY && diffAngleX == diffAngleY {
            target.rotation = startAngleX + diffAngleX * state
        } else {
            if rotateX {
                target.rotationalSkewX = startAngleX + diffAngleX * state
            }
            if rotateY {
                target.rotationalSkewY = startAngleY + diffAngleY * state
            }
        }
    }
}

/**
 This action rotates the target clockwise by the number of degrees specified.
 
 @warning Rotate actions shouldn't be used to rotate nodes with a dynamic PhysicsBody unless the body has allowsRotation set to NO.
 Otherwise both the physics body and the action will alter the node's rotation property, overriding each other's changes.
 This leads to unpredictable behavior.
 */
struct ActionRotateBy: ActionModel {
    private var startAngleX : Angle!
    private var startAngleY : Angle!
    private let rotateX: Bool
    private let rotateY: Bool
    private var target: Node!
    
    private let diffAngleY: Angle
    private let diffAngleX: Angle
    
    init(angle: Angle) {
        self.init(angleX: angle, angleY: angle)
    }
    
    init(angleX aX: Angle? = nil, angleY aY: Angle? = nil) {
        self.diffAngleX = aX ?? Angle.zero
        self.diffAngleY = aY ?? Angle.zero
        rotateX = aX != nil
        rotateY = aY != nil
    }
    
    mutating func start(with target: AnyObject?) {
        let target = target as! Node
        self.target = target
        self.startAngleX = target.rotationalSkewX
        self.startAngleY = target.rotationalSkewY
    
    }
    mutating func update(state: Float) {
        // added to support overriding setRotation only
        if startAngleX == startAngleY && diffAngleX == diffAngleY {
            target.rotation = startAngleX + diffAngleX * state
        } else {
            if rotateX {
                target.rotationalSkewX = startAngleX + diffAngleX * state
            }
            if rotateY {
                target.rotationalSkewY = startAngleY + diffAngleY * state
            }
        }
    }
}

/**
 *  This action skews the target to the specified angles. Skewing changes the rectangular shape of the node to that of a parallelogram.
 */
struct ActionSkewTo: ActionModel {
    private var skewX:         Float = 0.0
    private var skewY:         Float = 0.0
    private var startSkewX:    Float = 0.0
    private var startSkewY:    Float = 0.0
    private(set) var endSkewX: Float = 0.0
    private(set) var endSkewY: Float = 0.0
    private var deltaX:        Float = 0.0
    private var deltaY:        Float = 0.0
    
    private(set) var target: Node!
    
    /** @name Creating a Skew Action */
    /**
     *  Initializes the action.
     *
     *  @param sx X skew value in degrees, between -90 and 90.
     *  @param sy Y skew value in degrees, between -90 and 90.
     *
     *  @return New skew action.
     */
    init(skewX sx: Float, skewY sy: Float) {
        self.endSkewX = sx
        self.endSkewY = sy
    }
    
    mutating func start(with target: AnyObject?) {
        self.target = target as! Node
        let target = self.target!
        
        self.startSkewX = target.skewX
        if startSkewX > 0 {
            self.startSkewX = fmodf(startSkewX, 180.0)
        }
        else {
            self.startSkewX = fmodf(startSkewX, -180.0)
        }
        self.deltaX = endSkewX - startSkewX
        if deltaX > 180 {
            self.deltaX -= 360
        }
        if deltaX < -180 {
            self.deltaX += 360
        }
        self.startSkewY = target.skewY
        if startSkewY > 0 {
            self.startSkewY = fmodf(startSkewY, 360.0)
        }
        else {
            self.startSkewY = fmodf(startSkewY, -360.0)
        }
        self.deltaY = endSkewY - startSkewY
        if deltaY > 180 {
            self.deltaY -= 360
        }
        if deltaY < -180 {
            self.deltaY += 360
        }
    }
    
    mutating func update(state: Float) {
        target.skewX = startSkewX + deltaX * state
        target.skewY = startSkewY + deltaY * state
    }
}

/**
 *  This action skews a target by the specified skewX and skewY degrees values. Skewing changes the rectangular shape of the node to that of a parallelogram.
 */
struct ActionSkewBy: ActionModel {
    private var startSkewX:    Float = 0.0
    private var startSkewY:    Float = 0.0
    private let deltaX:        Float
    private let deltaY:        Float
    
    private(set) var target: Node!
    
    /** @name Creating a Skew Action */
    /**
     *  Initializes the action.
     *
     *  @param sx X skew value in degrees, between -90 and 90.
     *  @param sy Y skew value in degrees, between -90 and 90.
     *
     *  @return New skew action.
     */
    init(skewX sx: Float = 0.0, skewY sy: Float = 0.0) {
        self.deltaX = sx
        self.deltaY = sy
    }
    
    mutating func start(with target: AnyObject?) {
        self.target = target as! Node
        let target = self.target!
        
        self.startSkewX = target.skewX
        self.startSkewY = target.skewY
    }
    
    mutating func update(state: Float) {
        target.skewX = startSkewX + deltaX * state
        target.skewY = startSkewY + deltaY * state
    }
}
