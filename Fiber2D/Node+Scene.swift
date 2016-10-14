//
//  Node+Scene.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

extension Node: Enterable, Exitable {
    /** Called every time the Node (or one of its parents) has been added to the scene, or when the scene is presented.
     If a new scene is presented with a transition, this event is sent to nodes when the transition animation starts.
     
     @warning You must call `[super onEnter]` in your own implementation.
     @see onExit
     @see onEnterTransitionDidFinish
     */
    public func onEnter() {
        assert(self.scene != nil, "Missing scene on node. Was it not added to the hierarchy?")
        children.forEach { $0.onEnter() }
        scheduler!.schedule(target: self)
        let wasRunning: Bool = self.active
        // Add queued actions or scheduled code, if needed:
        for a in queuedActions {
            run(action: a)
        }
        self.queuedActions.removeAll()
        
        for c in queuedComponents {
            add(component: c)
        }
        self.queuedComponents.removeAll()
        
        components.forEach {
            director!.system(for: $0)?.add(component: $0)
            if let c = $0 as? Enterable { c.onEnter() }
        }
        self.isInActiveScene = true
        self.wasRunning(wasRunning)
    }
    
    /** Called every time the Node (or one of its parents) has been added to the scene, or when the scene is presented.
     If a new scene is presented with a transition, this event is sent to nodes after the transition animation ended. Otherwise
     it will be called immediately after onEnter.
     
     @warning You must call `[super onEnterTransitionDidFinish]` in your own implementation.
     @see onEnter
     @see onExit
     */
    public func onEnterTransitionDidFinish() {
        children.forEach { $0.onEnterTransitionDidFinish() }
    }
    
    /** Called every time the Node is removed from the node tree.
     If a new scene is presented with a transition, this event is sent when the transition animation starts.
     
     @warning You must call `[super onExitTransitionDidStart]` in your own implementation.
     @see onExit
     @see onEnter
     */
    public func onExitTransitionDidStart() {
        children.forEach { $0.onExitTransitionDidStart() }
    }
    
    /** Called every time the Node is removed from the node tree.
     If a new scene is presented with a transition, this event is sent when the transition animation ended.
     
     @warning You must call `[super onExit]` in your own implementation.
     @see onEnter
     @see onExitTransitionDidStart
     */
    public func onExit() {
        let wasRunning: Bool = self.active
        self.isInActiveScene = false
        self.wasRunning(wasRunning)
        
        components.forEach {
            if let c = $0 as? Exitable { c.onExit() }
            self.director!.system(for: $0)?.remove(component: $0)
        }
        if updatableComponents.count > 0 || fixedUpdatableComponents.count > 0 {
            scheduler!.unscheduleUpdates(from: self)
        }
        children.forEach { $0.onExit() }
    }
}
