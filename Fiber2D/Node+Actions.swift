//
//  Node+Actions.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

extension Node: CCSchedulableTarget {
    
    
}

extension Node {
    /**
     Has the node run an action.
     
     @note Depending on when in the frame update cycle this method gets called, the action passed in may either start running
     in the current frame or in the next frame.
     
     @param action Action to run.
     @return The action that is executed (same as the one that was passed in).
     @see CCAction
     */
    
    func runAction(_ action: Action) -> Action {
        let scheduler = self.scheduler
        if scheduler == nil {
            let block: ()->() = {() -> Void in
                self.scheduler!.add(action: action, target: self, paused: !self.active)
            }
            queuedActions.append(block)
        }
        else {
            scheduler!.add(action: action, target: self, paused: !self.active)
        }
        return action

    }
    /** Stops and removes all actions running on the node.
     @node It is not necessary to call this when removing a node. Removing a node from its parent will also stop its actions. */
    
    func stopAllActions() {
        scheduler?.removeAllActions(from: self)
    }
    /**
     *  Removes an action from the running action list.
     *
     *  @param action Action to remove.
     *  @see CCAction
     */
    
    func stopAction(_ action: Action) {
        scheduler?.remove(action: action, from: self)
    }
    /**
     *  Removes an action from the running action list given its tag. If there are multiple actions with the same tag it will
     *  only remove the first action found that has this tag.
     *
     *  @param name Name of the action to remove.
     */
    
    func stopActionByName(_ name: String) {
        scheduler?.removeAction(by: name, target: self)
    }
    /**
     *  Gets an action running on the node given its tag.
     *  If there are multiple actions with the same tag it will get the first action found that has this tag.
     *
     *  @param name Name of the action.
     *
     *  @return The first action with the given name, or nil if there's no running action with this name.
     *  @see CCAction
     */
    
    func getActionByName(_ name: String) -> Action? {
        return scheduler?.getAction(by: name, target: self)
    }
    /**
     Return a list of all actions associated with this node.
     
     @since v4.0
     */
    
    var actions: [Action]? {
        return scheduler?.actions(for: self)
    }
    /// -----------------------------------------------------------------------
    /// @name Scheduling Selectors and Blocks
    /// -----------------------------------------------------------------------
    /**
     Schedules a block to run once, after the given delay.
     
     `CCTimerBlock` is a block typedef declared as `void (^)(CCTimer *timer)`
     
     @note There is currently no way to stop/cancel an already scheduled block. If a scheduled block should not run under certain circumstances,
     the block's code itself must check these conditions to determine whether it should or shouldn't perform its task.
     
     @param block Block to execute. The block takes a `CCTimer*` parameter as input and returns nothing.
     @param delay Delay, in seconds.
     
     @return A newly initialized CCTimer object.
     @see CCTimer
     */
    
    func scheduleBlock(_ block: TimerBlock, delay: Time) -> Timer! {
        guard let scheduler = self.scheduler else {
            return nil
        }
        return scheduler.schedule(block: block, for: self, withDelay: delay)
    }
    
    // Used to pause/unpause a node's actions and timers when it's isRunning state changes.
    func wasRunning(_ wasRunning: Bool) {
        let isRunning = self.active
        // Resume or pause scheduled update methods, CCActions, and animations if the pause state has changed
        if isRunning != wasRunning {
            scheduler?.setPaused(paused: !isRunning, target: self)
        }
    }
    
    // Recursively increment/decrement _pausedAncestors on the children of 'node'.
    func recursivelyIncrementPausedAncestors(_ increment: Int) {
        for node in children {
            let wasRunning = node.active
            node.pausedAncestors += increment
            node.wasRunning(wasRunning)
            
            node.recursivelyIncrementPausedAncestors(increment)
        }
    }
}
