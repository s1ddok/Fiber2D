//
//  PhysicsSystem.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public class PhysicsSystem: System {
    public var paused: Bool = false
    
    public let world: PhysicsWorld
    
    public init(world: PhysicsWorld) {
        self.world = world
    }
    
    /**
     * Component related methods
     */
    public func add(component: Component) {
    }
    
    public func removeComponent(by tag: Int) {
    }
    
    public func wants(component: Component) -> Bool {
        return false//component is PhysicsBody
    }
    
    public func updatePhysics(delta: Time) {
        if world.autoStep {
            world.update(dt: delta)
        }
    }
}

extension PhysicsSystem: FixedUpdatable {
    public var priority: Int {
        return Int.min
    }
    
    public func fixedUpdate(delta: Time) {
        updatePhysics(delta: delta)
    }
}
