//
//  ActionInterval.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 29.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/**
 *  This action skews the target to the specified angles. Skewing changes the rectangular shape of the node to that of a parallelogram.
 */
class ActionSkewTo: ActionInterval {
    var skewX: Float = 0.0
    var skewY: Float = 0.0
    var startSkewX: Float = 0.0
    var startSkewY: Float = 0.0
    var endSkewX: Float = 0.0
    var endSkewY: Float = 0.0
    var deltaX: Float = 0.0
    var deltaY: Float = 0.0
    
    /** @name Creating a Skew Action */
    /**
     *  Initializes the action.
     *
     *  @param t  Action duration.
     *  @param sx X skew value in degrees, between -90 and 90.
     *  @param sy Y skew value in degrees, between -90 and 90.
     *
     *  @return New skew action.
     */
    
    init(duration t: Time, skewX sx: Float, skewY sy: Float) {
        super.init(duration: t)
        self.endSkewX = sx
        self.endSkewY = sy
    }
    
    override func start(with target: AnyObject) {
        super.start(with: target)
        let target = target as! Node
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
    
    override func update(time t: Time) {
        let target = self.target as! Node
        target.skewX = startSkewX + deltaX * t
        target.skewY = startSkewY + deltaY * t
    }
}
