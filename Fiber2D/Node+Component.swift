//
//  Node+Component.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 10.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public extension Node {
    /// @name component functions
    /**
     * Gets a component by its name.
     *
     * @param name A given tag of component.
     * @return The Component by tag.
     */
    public func getComponent(by tag: Int) -> Component? {
        return components.first { $0.tag == tag } ?? renderableComponents.first { $0.tag == tag }
    }
    
    /**
     * Gets a component by its type.
     *
     * @param name A given type of component.
     * @return The Component by type.
     */
    public func getComponent<U>(by type: U.Type) -> U?
    where U: Component {
        for c in components {
            if let retVal = c as? U {
                return retVal
            }
        }
        
        for rc in renderableComponents {
            if let retVal = rc as? U {
                return retVal
            }
        }
        return nil
    }
    
    /**
     * Adds a component.
     *
     * @param component A given component.
     * @return True if added success.
     */
    @discardableResult
    public func add(component: Component) -> Bool {
        guard let scene = self.scene else {
            queuedComponents.append(component)
            return false
        }
        
        guard component.owner == nil else {
            fatalError("ERROR: Component already add. It can't be added to more than one owner")
        }
        
        /*guard getComponent(by: component.tag) == nil else {
            return false
        }*/
        
        if let rc = component as? RenderableComponent {
            renderableComponents.insert(rc, at: renderableComponents.index { $0.zOrder >= rc.zOrder } ?? renderableComponents.count)
        } else {
            components.append(component)
        }
        component.onAdd(to: self)
        
        if isInActiveScene {
            let system = scene.system(for: component)
            system?.add(component: component)
        }
        
        if let c = component as? Updatable & Tagged {
            // TODO: Insert with priority in mind
            updatableComponents.append(c)
            
            // If it is first component
            if isInActiveScene && updatableComponents.count == 1 {
                scene.scheduler.schedule(updatable: self)
            }
        }
        
        if let c = component as? FixedUpdatable & Tagged {
            // TODO: Insert with priority in mind
            fixedUpdatableComponents.append(c)
            
            // If it is first component
            if isInActiveScene && fixedUpdatableComponents.count == 1 {
                scene.scheduler.schedule(fixedUpdatable: self)
            }
        }
    
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
        return removeComponent(with: { $0.tag == tag })
    }
    
    /**
       Removes all components with given tag
     */
    public func removeAllComponents(by tag: Int) {
        while removeComponent(by: tag) {}
    }
    
    /**
     * Removes a component by its value.
     *
     * @param component A given component.
     * @return True if removed success.
     */
    @discardableResult
    public func remove(component: Component) -> Bool {
        return removeComponent(by: component.tag)
    }

    /**
     * Removes a component by its type.
     *
     * @param component A given component type.
     * @return True if removed success.
     */
    @discardableResult
    public func removeComponent<U>(by type: U.Type) -> Bool {
        return removeComponent(with: { $0 is U })
    }
    
    /**
     * Removes all components of given type
     */
    public func removeAllComponents<U>(by type: U.Type) {
        while removeComponent(by: type) {}
    }
    
    /**
     * Removes all components
     */
    public func removeAllComponents() {
        components.forEach {
            $0.onRemove()
        }
        components = []
        updatableComponents = []
        fixedUpdatableComponents = []
        
        let scheduler = self.scheduler
        scheduler?.unschedule(updatable: self)
        scheduler?.unschedule(fixedUpdatable: self)
    }    
}

fileprivate extension Node {
    @inline(__always)
    fileprivate func removeComponent(with block: (Component) -> Bool) -> Bool {
        // if it still waits to be added
        if let idx = queuedComponents.index(where: block) {
            queuedComponents.remove(at: idx)
            return true
        }
        
        var c: Component!
        
        // if it is already added
        if let idx = components.index(where: block) {
            c = components[idx]
            components.remove(at: idx)
        }
        
        if let idx = renderableComponents.index(where: block) {
            c = renderableComponents[idx]
            renderableComponents.remove(at: idx)
        }
        
        guard c != nil else {
            return false
        }
        
        scene?.system(for: c)?.remove(component: c)
        
        c.onRemove()
        
        if let uc = c as? Updatable & AnyObject {
            if let idx = updatableComponents.index(where: { $0 === uc } ) {
                updatableComponents.remove(at: idx)
            }
            
            if self.updatableComponents.isEmpty {
                self.scheduler?.unschedule(updatable: self)
            }
        }
        
        if let fuc = c as? FixedUpdatable & AnyObject {
            if let idx = fixedUpdatableComponents.index(where: { $0 === fuc } ) {
                fixedUpdatableComponents.remove(at: idx)
            }
            
            if self.fixedUpdatableComponents.isEmpty {
                self.scheduler?.unschedule(fixedUpdatable: self)
            }
        }
        
        return true
    }
}


extension Node: Updatable, FixedUpdatable {
    
    public final func update(delta: Time) {
        updatableComponents.forEach { $0.update(delta: delta) }
    }
    
    public final func fixedUpdate(delta: Time) {
        // this is a workaround of what seems to be a Swift compiler bug
        // commented line does not work ...
        for c in fixedUpdatableComponents as [FixedUpdatable] {
            c.fixedUpdate(delta: delta)
        }
        //fixedUpdatableComponents.forEach { $0.fixedUpdate(delta: delta) }
    }
    
}
