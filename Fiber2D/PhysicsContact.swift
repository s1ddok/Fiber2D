//
//  PhysicsContact.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 22.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public enum EventCode {
    case none, begin, presolve, postsolve, separate
    
}

public struct PhysicsContactData {
    
}

/**
 * @brief Contact information.
 
 * It will created automatically when two shape contact with each other. And it will destroyed automatically when two shape separated.
 */
public struct PhysicsContact {
    /** Get contact shape A. */
    public unowned var shapeA: PhysicsShape
    
    /** Get contact shape B. */
    public unowned var shapeB: PhysicsShape
    
    /** Get contact data */
    public let contactData: PhysicsContactData
    
    /** Get previous contact data */
    public let previousContactData: PhysicsContactData
    
    public let data: OpaquePointer
    
    private func generateContactData() {
        
    }
}
