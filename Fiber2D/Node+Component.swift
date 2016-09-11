//
//  Node+Component.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 10.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

// TODO:
// Add to scheduler only nodes with at least one component
public extension Node {
    /// @name component functions
    /**
     * Gets a component by its name.
     *
     * @param name A given tag of component.
     * @return The Component by tag.
     */
    public func getComponent(by tag: Int) -> Component? {
        return components.first { $0.tag == tag }
    }
    
    /**
     * Adds a component.
     *
     * @param component A given component.
     * @return True if added success.
     */
    @discardableResult
    public func add(component: Component) -> Bool {
        guard component.owner == nil else {
            fatalError("ERROR: Component already add. It can't be added to more than one owner")
        }
        
        guard getComponent(by: component.tag) == nil else {
            return false
        }
        components.append(component)
        component.owner = self
        component.onAdd()
        
        // should enable schedule update, then all components can receive this call back
        //scheduleUpdate()
        
        return true
    }
    
    /**
     * Removes all components with tag.
     *
     * @param name A given tag of components.
     * @return True if removed success.
     */
    @discardableResult
    public func removeComponent(by tag: Int) -> Bool {
        let oldCount = components.count
        components = components.filter {
            if $0.tag == tag {
                $0.onRemove()
                $0.owner = nil
            
                return false
            }
            return true
        }
        return oldCount < components.count
    }
    
    /**
     * Removes a component by its pointer.
     *
     * @param component A given component.
     * @return True if removed success.
     */
    @discardableResult
    public func remove(component: Component) -> Bool {
        return components.removeObject(component)
    }
    
    /**
     * Removes all components
     */
    public func removeAllComponents() {
        components.forEach {
            $0.onRemove()
            $0.owner = nil
        }
        components = []
        //unscheduleUpdate()
    }    
}

extension Node: Updatable {
    public final func update(delta: Time) {
        components.forEach { $0.update(delta: delta) }
    }
    public final func fixedUpdate(delta: Time) {
        components.forEach { $0.fixedUpdate(delta: delta) }
    }
}
