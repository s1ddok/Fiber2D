//
//  ActionTransform.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 03.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

/**
 This action rotates the target to the specified angle.
 The direction will be decided by the shortest route.
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
    private var skewX:         Angle = 0°
    private var skewY:         Angle = 0°
    private var startSkewX:    Angle = 0°
    private var startSkewY:    Angle = 0°
    private(set) var endSkewX: Angle = 0°
    private(set) var endSkewY: Angle = 0°
    private var deltaX:        Angle = 0°
    private var deltaY:        Angle = 0°
    
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
    init(skewX sx: Angle, skewY sy: Angle) {
        self.endSkewX = sx
        self.endSkewY = sy
    }
    
    mutating func start(with target: AnyObject?) {
        self.target = target as! Node
        let target = self.target!
        
        // X
        self.startSkewX = target.skewX
        self.startSkewX = startSkewX % (self.startSkewX > Angle.zero ? Angle.pi : -Angle.pi)
        self.deltaX = endSkewX - startSkewX
        if deltaX > Angle.pi {
            self.deltaX -= Angle.pi2
        }
        if deltaX < -Angle.pi {
            self.deltaX += Angle.pi2
        }
        
        // Y
        self.startSkewY = target.skewY
        self.startSkewY = startSkewY % (startSkewY > Angle.zero ? Angle.pi2 : -Angle.pi2)
        self.deltaY = endSkewY - startSkewY
        if deltaY > Angle.pi {
            self.deltaY -= Angle.pi2
        }
        if deltaY < -Angle.pi {
            self.deltaY += Angle.pi2
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
    private var startSkewX:    Angle = 0°
    private var startSkewY:    Angle = 0°
    private let deltaX:        Angle
    private let deltaY:        Angle
    
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
    init(skewX sx: Angle = 0°, skewY sy: Angle = 0°) {
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

/**
 This action moves the target to the position specified, these are absolute coordinates.
 Several MoveTo actions can be concurrently called, and the resulting movement will be the sum of individual movements.
 */
struct ActionMoveTo: ActionModel {
    private var startPosition: Point!
    private let endPosition: Point
    
    private(set) var target: Node!
    
    /** @name Creating a Move Action */
    
    /**
     *  Creates the action.
     *
     *  @param position Absolute position to move to.
     *
     *  @return New moveto action.
     */
    init(_ p: Point) {
        endPosition = p
    }
    
    mutating func start(with target: AnyObject?) {
        self.target = target as! Node
        let target = self.target!
        
        self.startPosition = target.position
    }
    
    mutating func update(state: Float) {
        target.position = startPosition.interpolated(to: endPosition, factor: state)
    }
}

/**
 This action moves the target by the x,y values in the specified point value.
 X and Y are relative to the position of the object.
 Several MoveBy actions can be concurrently called, and the resulting movement will be the sum of individual movements.
 */
struct ActionMoveBy: ActionModel {
    private var startPosition: Point!
    public let deltaPosition: Point
    #if ENABLE_STACKABLE_ACTIONS
    private var previousPosition: Point!
    #endif
    private(set) var target: Node!
    
    /** @name Creating a Move Action */
    
    /**
     *  Creates the action.
     *
     *  @param deltaPosition Delta position.
     *
     *  @return New moveby action.
     */
    init(_ p: Point) {
        deltaPosition = p
    }
    
    mutating func start(with target: AnyObject?) {
        self.target = target as! Node
        let target = self.target!
        
        self.startPosition = target.position
        #if ENABLE_STACKABLE_ACTIONS
        self.previousPosition = startPosition
        #endif
    }
    
    mutating func update(state: Float) {
        #if ENABLE_STACKABLE_ACTIONS
        let currentPosition = target.position
        let diff = currentPosition - previousPosition
        startPosition = startPosition + diff
        let newPos = startPosition + deltaPosition * state
        target.position = newPos
        previousPosition = newPos
        #else
        target.position = startPosition + deltaPosition * state
        #endif
    }
    
}
