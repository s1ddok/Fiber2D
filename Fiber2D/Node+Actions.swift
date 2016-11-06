//
//  Node+Actions.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

public extension Node {
    /**
     Has the node run an action.
     
     @note Depending on when in the frame update cycle this method gets called, the action passed in may either start running
     in the current frame or in the next frame.
     
     @param action ActionContainer to run.
     @return The action that is executed (same as the one that was passed in).
     @see ActionContainer
     */
    public func run(action: ActionContainer) {
        if let scheduler = self.scheduler {
            scheduler.add(action: action, target: self, paused: !self.active)
        } else {
            queuedActions.append(action)
        }
    }
    
    /** Stops and removes all actions running on the node.
     @node It is not necessary to call this when removing a node. Removing a node from its parent will also stop its actions. */
    public func stopAllActions() {
        queuedActions = []
        scheduler?.removeAllActions(from: self)
    }

    /**
     *  Removes an action from the running action list given its tag. If there are multiple actions with the same tag it will
     *  only remove the first action found that has this tag.
     *
     *  @param name Name of the action to remove.
     */
    public func stopAction(by tag: Int) {
        if let idx = queuedActions.index(where: { $0.tag == tag }) {
            queuedActions.remove(at: idx)
            return
        }
        scheduler?.removeAction(by: tag, target: self)
    }
    
    /**
     *  Gets an action running on the node given its tag.
     *  If there are multiple actions with the same tag it will get the first action found that has this tag.
     *
     *  @param name Name of the action.
     *
     *  @return The first action with the given name, or nil if there's no running action with this name.
     *  @see ActionContainer
     */
    public func getAction(by tag: Int) -> ActionContainer? {
        return scheduler?.getAction(by: tag, target: self)
    }
    
    /**
     Return a list of all actions associated with this node.
     */
    public var actions: [ActionContainer]? {
        return scheduler?.actions(for: self)
    }
    
    /// -----------------------------------------------------------------------
    /// @name Scheduling Blocks
    /// -----------------------------------------------------------------------
    /**
     Schedules a block to run once, after the given delay.
     
     `TimerBlock` is a block typedef declared as `(Timer) -> Void`
     
     @note There is currently no way to stop/cancel an already scheduled block. If a scheduled block should not run under certain circumstances,
     the block's code itself must check these conditions to determine whether it should or shouldn't perform its task.
     
     @param block Block to execute. The block takes a `Timer*` parameter as input and returns nothing.
     @param delay Delay, in seconds.
     
     @return A newly initialized Timer object.
     @see Timer
     */
    public func schedule(block: @escaping TimerBlock, delay: Time) -> Timer! {
        guard let scheduler = self.scheduler else {
            return nil
        }
        return scheduler.schedule(block: block, for: self, withDelay: delay)
    }
}

// Internal scheduling stuff
internal extension Node {
    
    // Used to pause/unpause a node's actions and timers when it's isRunning state changes.
    internal func wasRunning(_ wasRunning: Bool) {
        let isRunning = self.active
        // Resume or pause scheduled update methods, Actions, and animations if the pause state has changed
        if isRunning != wasRunning {
            scheduler?.setPaused(paused: !isRunning, target: self)
        }
    }
    
    // Recursively increment/decrement _pausedAncestors on the children of 'node'.
    internal func recursivelyIncrementPausedAncestors(_ increment: Int) {
        for node in children {
            let wasRunning = node.active
            node.pausedAncestors += increment
            node.wasRunning(wasRunning)
            
            node.recursivelyIncrementPausedAncestors(increment)
        }
    }
}
