//
//  PhysicsContact.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 22.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

public enum EventCode {
    case none, begin, presolve, postsolve, separate
}

/**
 * An object that implements the PhysicsContactDelegate protocol can respond 
 * when two physics bodies are in contact with each other in a physics world. 
 * To receive contact messages, you set the contactDelegate property of a PhysicsWorld object.
 * The delegate is called when a contact starts or ends.
 */
public protocol PhysicsContactDelegate: class {
    /** Called when two bodies first contact each other. */
    func didBegin(contact: PhysicsContact)
    
    /** Called when the contact ends between two physics bodies. */
    func didEnd(contact: PhysicsContact)
}

public struct PhysicsContactData {
    let points: [Point]
    let normal: Vector2f
}

/**
 * @brief Contact information.
 
 * It will be created automatically when two shape contact with each other. 
 * And it will be destroyed automatically when two shape separated.
 */
public struct PhysicsContact {
    /** Get contact shape A. */
    public unowned var shapeA: PhysicsShape
    
    /** Get contact shape B. */
    public unowned var shapeB: PhysicsShape
    
    /** Get contact data */
    public var contactData: PhysicsContactData
    
    /** Get previous contact data */
    //public let previousContactData: PhysicsContactData
    
    internal let arbiter: UnsafeMutablePointer<cpArbiter>!
    
    internal init(shapeA: PhysicsShape, shapeB: PhysicsShape, arb: UnsafeMutablePointer<cpArbiter>!) {
        self.shapeA = shapeA
        self.shapeB = shapeB
        self.arbiter = arb
        let count = cpArbiterGetCount(arb)
        var points = [Point](repeating: Point.zero, count: Int(count))
        for i in 0..<count {
            points[Int(i)] = Point(cpArbiterGetPointA(arb, i))
        }
        
        let normal = count == 0 ? vec2.zero : vec2(cpArbiterGetNormal(arb))
        self.contactData = PhysicsContactData(points: points, normal: normal)
    }
}


/**
 * @brief Presolve value generated when onContactPreSolve called.
 */
public struct PhysicsContactPreSolve {
    /** Get elasticity between two bodies.*/
    let elasticity: Float
    /** Get friction between two bodies.*/
    let friction: Float
    /** Get surface velocity between two bodies.*/
    let surfaceVelocity: Vector2f
    
    internal var contactInfo: OpaquePointer
    /** Ignore the rest of the contact presolve and postsolve callbacks. */
    func ignore() {
    }
}

/**
 * @brief Postsolve value generated when onContactPostSolve called.
 */
public struct PhysicsContactPostSolve {
    /** Get elasticity between two bodies.*/
    let elasticity: Float
    /** Get friction between two bodies.*/
    let friction: Float
    /** Get surface velocity between two bodies.*/
    let surfaceVelocity: Vector2f

    internal var contactInfo: OpaquePointer
}
