//
//  System.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 26.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public protocol System: class, Enterable, Exitable, Pausable {
    
    func onAdd(to director: Director)
    func onRemove()
    
    /**
      * Component related methods
      */
    func add(component: Component)
    func removeComponent(by tag: Int)
    
    /** Returns true if system needs to know about certain type of components
      * This method is called for every component that is added to the node
      * Ex. implementation for PhysicsSystem will look like this:
      * *** public func wants(component: Component) -> Bool {
      * ***    return component is PhysicsBody
      * *** }
      * @note that if multiple systems will want same type of components,
      * it will lead to undefined behaviour
      */
    func wants(component: Component) -> Bool
}

// default implementations AKA optional methods
public extension System {
    func onAdd(to director: Director) {}
    func onRemove() {}
    func onEnter() {}
    func onExit() {}
}
