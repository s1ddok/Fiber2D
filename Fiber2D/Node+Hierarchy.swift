//
//  Node+Children.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 27.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public extension Node {
    
    // MARK: Hierarchy
    
    /// @name Working with Node Trees

    /** A weak reference to the parent. */
    public var parent: Node? {
        get { return _parent }
        set {
            if _parent != nil {
                removeFromParent(cleanup: false)
            }
            _parent = newValue
            parent?.add(child: self)
        }
    }
    
    /**
     Adds a child to the container with z order and tag.
     If the child is added to a 'running' node, then 'onEnter' and 'onEnterTransitionDidFinish' will be called immediately.
     
     @param node Node to add as a child.
     @param z    Draw order of node. This value will be assigned to the node's zOrder property.
     @param name Name for this node. This string will be assigned to the node's name property.
     @see zOrder
     @see name
     @note "add" logic MUST only be on this method
     * If a class want's to extend the 'add child' behaviour it only needs
     * to override this method
     */
    public func add(child: Node, z: Int? = nil, name: String? = nil) {
        assert(child.parent == nil, "child already added to another node. It can't be added again")
        assert((child as? Scene) == nil, "Scenes may not be added as children of other nodes or scenes. Only one scene can exist in a hierarchy.")
        child.zOrder = z ?? child.zOrder
        child.name = name ?? child.name
        child._parent = self
        // this is needed for the case when node has Normalize positon type and switched parents
        // we should've add method `parentContentSizeChanged` and trigger that instead
        child.isTransformDirty = true
        children.append(child)
        self.isReorderChildDirty = true
        // Update pausing parameters
        child.pausedAncestors = pausedAncestors + (paused ? 1 : 0)
        child.recursivelyIncrementPausedAncestors(child.pausedAncestors)
        if isInActiveScene {
            child._onEnter()
            child._onEnterTransitionDidFinish()
        }
        
        childWasAdded(child: child)
        Director.currentDirector!.responderManager.markAsDirty()
    }
    
    /** Removes the node from its parent node. Will stop the node's scheduled selectors/blocks and actions.
     @note It is typically more efficient to change a node's visible status rather than remove + add(child: if all you need
     is to temporarily remove the node from the screen.
     @see visible */
    public func removeFromParent(cleanup: Bool = true) {
        parent?.remove(child: self, cleanup: cleanup)
    }
    
    /**
     Removes a child from the container. The node must be a child of this node.
     Will stop the node's scheduled selectors/blocks and actions.
     
     @note It is recommended to use `[node removeFromParent]` over `[self removeChild:node]` as the former will always work,
     even in cases where (in this example) the node hierarchy has changed so that node no longer is a child of self.
     
     @note It is typically more efficient to change a node's visible status rather than remove + add(child: if all you need
     is to temporarily remove the node from the screen.
     
     @param child The child node to remove.
     @see removeFromParent
     */
    public func remove(child: Node, cleanup: Bool = true) {
        detach(child: child, cleanup: cleanup)
    }
    /**
     Removes a child from the container by name. Does nothing if there's no node with that name.
     Will stop the node's scheduled selectors/blocks and actions.
     
     @param name Name of node to be removed.
     */
    public func removeChild(by name: String, cleanup: Bool = true) {
        guard let child = getChild(by: name, recursively: false) else {
            print("WARNING: Node doesn't contain specified child")
            return
        }
        
        detach(child: child, cleanup: cleanup)
    }
    
    /**
     Removes all children from the container.
     @note It is unnecessary to call this when replacing scenes or removing nodes. All nodes call this method on themselves automatically
     when removed from a parent node or when a new scene is presented.
     */
    public func removeAllChildren(cleanup: Bool = true) {
        // not using detachChild improves speed here
        for c: Node in children {
            // IMPORTANT:
            //  -1st do onExit
            //  -2nd cleanup
            if self.isInActiveScene {
                c._onExitTransitionDidStart()
                c._onExit()
            }
            c.recursivelyIncrementPausedAncestors(-c.pausedAncestors)
            c.pausedAncestors = 0
            if cleanup {
                c.cleanup()
            }
            // set parent nil at the end (issue #476)
            c.parent = nil
            Director.currentDirector!.responderManager.markAsDirty()
        }
        children.removeAll()
    }
    
    /** final method called to actually remove a child node from the children.
     *  @param node    The child node to remove
     *  @param cleanup Stops all scheduled events and actions
     */
    public func detach(child: Node, cleanup doCleanup: Bool) {
        // IMPORTANT:
        //  -1st do onExit
        //  -2nd cleanup
        if self.isInActiveScene {
            child._onExitTransitionDidStart()
            child._onExit()
        }
        child.recursivelyIncrementPausedAncestors(-child.pausedAncestors)
        child.pausedAncestors = 0
        // If you don't do cleanup, the child's actions will not get removed and the
        // its scheduledSelectors_ dict will not get released!
        if doCleanup {
            child.cleanup()
        }
        // set parent nil at the end (issue #476)
        child._parent = nil
        Director.currentDirector!.responderManager.markAsDirty()
        children.removeObject(child)
        childWasRemoved(child: child)
    }
    
    /** performance improvement, Sort the children array once before drawing, instead of every time when a child is added or reordered
     don't call this manually unless a child added needs to be removed in the same frame */
    internal func sortAllChildren() {
        if isReorderChildDirty {
            children.sort { $0.zOrder < $1.zOrder }
            
            //don't need to check children recursively, that's done in visit of each child
            self.isReorderChildDirty = false
            Director.currentDirector!.responderManager.markAsDirty()
        }
    }
    
    /// Recursively get a child by name, but don't return the root of the search.
    private func getChildRecursive(by name: String, root: Node) -> Node? {
        if self !== root && (name == name) { return self }
        for node in children {
            let n = node.getChildRecursive(by: name, root: root)
            if n != nil {
                return n
            }
        }
        // not found
        return nil
    }
    
    /**
     Search through the children of the container for one matching the name tag.
     If recursive, it returns the first matching node, via a depth first search.
     Otherwise, only immediate children are checked.
     
     @note Avoid calling this often, ie multiple times per frame, as the lookup cost can add up. Specifically if the search is recursive.
     
     @param name The name of the node to look for.
     @param isRecursive Search recursively through node's children (its node tree).
     @return Returns the first node with a matching name, or nil if no node with that name was found.
     @see name
     */
    public func getChild(by name: String, recursively isRecursive: Bool) -> Node? {
        if isRecursive {
            return self.getChildRecursive(by: name, root: self)
        }
        else {
            for node in children {
                if node.name == name {
                    return node
                }
            }
        }
        // not found
        return nil
    }
}
