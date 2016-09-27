//
//  PhysicsSystem.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public class PhysicsSystem: System {
    /**
     * Component related methods
     */
    public func add(component: Component) {
        
        
    }
    
    public func removeComponent(by tag: Int) {
        
        
    }
    
    public func wants(component: Component) -> Bool {
        return component is PhysicsBody
    }
    
}
