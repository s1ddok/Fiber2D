//
//  PhysicsTypes.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 18.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

let CP_ALL_CATEGORIES: UInt32 = UInt32.max

let PHYSICS_INFINITY = Float.infinity
let MASS_DEFAULT:   Float = 1
let MOMENT_DEFAULT: Float = 200

public enum DebugDrawOption {
    case shape, joint, contact
}

internal extension Vector2f {
    
    init(_ cpv: cpVect) {
        self.init(x: Float(cpv.x), y: Float(cpv.y))
    }
    
    var cpVect: cpVect { return cpv(cpFloat(x), cpFloat(y)) }
}

internal extension cpVect {
    init(_ vec2: Vector2f) {
        self.init(x: cpFloat(vec2.x), y: cpFloat(vec2.y))
    }
}

internal extension Angle {
    init(_ cpf: cpFloat) {
        self.init(degrees: Float(cpf))
    }
}
