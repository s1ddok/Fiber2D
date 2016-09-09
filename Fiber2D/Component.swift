//
//  Component.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 09.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/**
 * Base class for everything attached to Nodes.
 */
open class Component: Tagged, Updatable {
    public weak var owner: Node?
    
    public var tag: Int = 0
    
    public var priority: Int = 0
    
    open func onEnter()  {}
    open func onExit()   {}
    open func onAdd()    {}
    open func onRemove() {}
    
    open func update(delta: Time) {}
    open func fixedUpdate(delta: Time) {}
}

extension Component: Equatable {
    public static func ==(lhs: Component, rhs: Component) -> Bool {
        return lhs.tag == rhs.tag
    }
}
