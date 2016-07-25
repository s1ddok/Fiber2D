//
//  Node+Scene.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation

extension Node {
    /** The scene this node is added to, or nil if it's not part of a scene.
     
     @note The scene property is nil during a node's init methods. The scene property is set only after addChild: was used to add it
     as a child node to a node that already is in the scene.
     @see Scene */
    var scene: Scene? {
        return parent?.scene
    }
    
    /** Called every time the Node (or one of its parents) has been added to the scene, or when the scene is presented.
     If a new scene is presented with a transition, this event is sent to nodes when the transition animation starts.
     
     @warning You must call `[super onEnter]` in your own implementation.
     @see onExit
     @see onEnterTransitionDidFinish
     */
    func onEnter() {
        assert(self.scene != nil, "Missing scene on node. Was it not added to the hierarchy?")
        children.forEach { $0.onEnter() }
        scene!.scheduler.scheduleTarget(self)
        let wasRunning: Bool = self.active
        self.isInActiveScene = true
        // Add queued actions or scheduled code, if needed:
        for block: dispatch_block_t in queuedActions {
            block()
        }
        self.queuedActions.removeAll()
        self.wasRunning(wasRunning)
    }
    
    /** Called every time the Node (or one of its parents) has been added to the scene, or when the scene is presented.
     If a new scene is presented with a transition, this event is sent to nodes after the transition animation ended. Otherwise
     it will be called immediately after onEnter.
     
     @warning You must call `[super onEnterTransitionDidFinish]` in your own implementation.
     @see onEnter
     @see onExit
     */
    func onEnterTransitionDidFinish() {
        children.forEach { $0.onEnterTransitionDidFinish() }
    }
    
    /** Called every time the Node is removed from the node tree.
     If a new scene is presented with a transition, this event is sent when the transition animation starts.
     
     @warning You must call `[super onExitTransitionDidStart]` in your own implementation.
     @see onExit
     @see onEnter
     */
    func onExitTransitionDidStart() {
        children.forEach { $0.onExitTransitionDidStart() }
    }
    
    /** Called every time the Node is removed from the node tree.
     If a new scene is presented with a transition, this event is sent when the transition animation ended.
     
     @warning You must call `[super onExit]` in your own implementation.
     @see onEnter
     @see onExitTransitionDidStart
     */
    func onExit() {
        let wasRunning: Bool = self.active
        self.isInActiveScene = false
        self.wasRunning(wasRunning)
        children.forEach { $0.onExit() }
    }
}