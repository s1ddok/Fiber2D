//
//  Node+Scene.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

internal extension Node {
    internal func _onEnter() {
        assert(self.scene != nil, "Missing scene on node. Was it not added to the hierarchy?")
        children.forEach { $0._onEnter() }
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
        
        scheduler!.schedule(target: self)
        
        self.isInActiveScene = true
        self.wasRunning(wasRunning)
        
        components.forEach {
            scene!.system(for: $0)?.add(component: $0)
        }
        onEnter.fire(())
    }
    
    internal func _onEnterTransitionDidFinish() {
        children.forEach { $0._onEnterTransitionDidFinish() }
        onEnterTransitionDidFinish.fire(())
    }
    
    internal func _onExitTransitionDidStart() {
        children.forEach { $0._onExitTransitionDidStart() }
        onExitTransitionDidStart.fire(())
    }

    internal func _onExit() {
        let wasRunning: Bool = self.active
        self.isInActiveScene = false
        self.wasRunning(wasRunning)
        
        components.forEach {
            self.scene!.system(for: $0)?.remove(component: $0)
        }
        if updatableComponents.count > 0 || fixedUpdatableComponents.count > 0 {
            scheduler!.unscheduleUpdates(from: self)
        }
        onExit.fire(())
        children.forEach { $0._onExit() }
    }
}
