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

        if let s = system as? Updatable & Pausable {
            runningScene?.scheduler.schedule(updatable: s)
        }
        
        if let s = system as? FixedUpdatable & Pausable {
            runningScene?.scheduler.schedule(fixedUpdatable: s)
        }
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
    
    public func system<U>(for type: U.Type) -> U?
    where U: System {
        for s in systems {
            if let retVal = s as? U {
                return retVal
            }
        }
        
        return nil
        
    }
    
}
