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
open class Component: Tagged {
    public weak var owner: Node?
    
    public var tag: Int = 0
    
    open func onAdd(to owner: Node) {
        self.owner = owner
    }
    
    open func onRemove() {
        self.owner = nil
    }
}

extension Component: Equatable {
    public static func ==(lhs: Component, rhs: Component) -> Bool {
        return lhs.tag == rhs.tag
    }
}
