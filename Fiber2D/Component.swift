//
//  Component.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 09.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/**
 * Protocol for all components. Implemented as protocol to allow structs for components as well.
 *
 * @note You have to remember owner in onAdd implementation, it is not set anywhere internally
 */
public protocol Component: Tagged {
    weak var owner: Node? { get /*set*/}
    
    func onAdd(to owner: Node)
    func onRemove()
}

/**
 * Components are meant to be unique by tag withing one Node
 */
/*extension Component: Equatable {
    public static func ==(lhs: Component, rhs: Component) -> Bool {
        return lhs.tag == rhs.tag
    }
}*/

/**
 * Base class for everything attached to Nodes.
 */
open class ComponentBase: Component {
    public weak var owner: Node?
    
    open var tag: Int = 0
    
    open func onAdd(to owner: Node) {
        self.owner = owner
    }
    
    open func onRemove() {
        self.owner = nil
    }
}


