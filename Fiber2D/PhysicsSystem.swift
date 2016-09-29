//
//  PhysicsSystem.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

internal struct PhysicsNode {
    unowned let node: Node
    weak var physicsBody: PhysicsBody?
    
    var children = [PhysicsNode]()
}

public class PhysicsSystem: System {
    public var ownsComponents: Bool {
        return false
    }
    public var paused: Bool = false
    public var dirty: Bool = true
    public let world: PhysicsWorld
    internal var rootNode: PhysicsNode!
    
    public init(world: PhysicsWorld) {
        self.world = world
    }
    
    /**
     * Component related methods
     */
    public func add(component: Component) {
        dirty = true
    }
    
    public func removeComponent(by tag: Int) {
        dirty = true
    }
    
    public func wants(component: Component) -> Bool {
        return component is PhysicsBody
    }
    
    public func updatePhysics(delta: Time) {
        if dirty {
            updatePhysicsBodyTree()
            dirty = false
        }
        
        if world.autoStep {
            let sceneToWorldTransform = rootNode.node.nodeToParentMatrix
            rootNode.beforeSimulation(parentToWorldTransform: sceneToWorldTransform,
                                      nodeParentScaleX: 1, nodeParentScaleY: 1,
                                      parentRotation: Angle.zero)
            
            world.update(dt: delta)
            
            // Update physics position, should loop as the same sequence as node tree.
            rootNode.afterSimulation(parentToWorldTransform: sceneToWorldTransform, parentRotation: Angle.zero)
        }
    }
    
    public func updatePhysicsBodyTree() {
        rootNode = world.rootNode.subtree
    }
}

extension PhysicsSystem: FixedUpdatable {
    public var priority: Int {
        return Int.min
    }
    
    public func fixedUpdate(delta: Time) {
        updatePhysics(delta: delta)
    }
}

internal extension Node {
    var subtree: PhysicsNode {
        let body = self.getComponent(by: PhysicsBody.self)
        var children = [PhysicsNode]()
        for c in self.children {
            let subtree = c.subtree
            if subtree.physicsBody != nil || subtree.children.count > 0 {
                children.append(subtree)
            }
        }
        
        return PhysicsNode(node: self, physicsBody: body, children: children)
    }
}

internal extension PhysicsNode {
    internal func beforeSimulation(parentToWorldTransform: Matrix4x4f, nodeParentScaleX: Float, nodeParentScaleY: Float, parentRotation: Angle) {
        let scaleX = nodeParentScaleX * node.scaleX
        let scaleY = nodeParentScaleY * node.scaleY
        let rotation = parentRotation + node.rotation
        
        let nodeToWorldTransform = parentToWorldTransform * node.nodeToParentMatrix
        
        physicsBody?.beforeSimulation(parentToWorldTransform: parentToWorldTransform, nodeToWorldTransform: nodeToWorldTransform, scaleX: scaleX, scaleY: scaleY, rotation: rotation)
        
        for c in children {
            c.beforeSimulation(parentToWorldTransform: nodeToWorldTransform,
                               nodeParentScaleX: scaleX, nodeParentScaleY: scaleY,
                               parentRotation: rotation)
        }
    }
    
    internal func afterSimulation(parentToWorldTransform: Matrix4x4f, parentRotation: Angle) {
        let nodeToWorldTransform = parentToWorldTransform * node.nodeToParentMatrix
        let nodeRotation = parentRotation + node.rotation
        
        physicsBody?.afterSimulation(parentToWorldTransform: parentToWorldTransform, parentRotation: parentRotation)
        
        for c in children {
            c.afterSimulation(parentToWorldTransform: nodeToWorldTransform, parentRotation: nodeRotation)
        }
    }
}
