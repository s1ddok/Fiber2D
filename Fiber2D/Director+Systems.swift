//
//  Director+Systems.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 26.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public extension Director {
    public func register(system: System) {
        let idx = systems.first { s in s === system }
        
        guard idx == nil else {
            return
        }
        
        systems.append(system)
        system.onAdd(to: self)
    }
    
    public func remove(system: System) {
        systems.removeObject(system)
        system.onRemove()
    }
    
    public func system(for component: Component) -> System? {
        for s in systems {
            if s.wants(component: component) {
                return s
            }
        }
        
        return nil
    }
    
}
