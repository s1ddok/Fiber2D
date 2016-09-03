//
//  ActionTransform.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 03.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

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
