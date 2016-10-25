//
//  System.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 26.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public protocol System: class, Enterable, Exitable, Pausable {
    
    func onAdd(to scene: Scene)
    func onRemove()
    
    /**
      * Component related methods
      */
    func add(component: Component)
    func remove(component: Component)
    
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
    func onAdd(to scene: Scene) {}
    func onRemove() {}
    func onEnter() {}
    func onExit() {}
}

public struct ComponentNode<T> where T: ComponentBase {
    unowned let node: Node
    weak var component: T?
    
    var children = [ComponentNode<T>]()
}

public extension Node {
    public func subtree<T>(of type: T.Type) -> ComponentNode<T>
    where T: Component {
        let body = self.getComponent(by: type)
        var children = [ComponentNode<T>]()
        for c in self.children {
            let subtree = c.subtree(of: type)
            if subtree.component != nil || subtree.children.count > 0 {
                children.append(subtree)
            }
        }
        
        return ComponentNode(node: self, component: body, children: children)
    }
}
