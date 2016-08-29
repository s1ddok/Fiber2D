//
//  Actions.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public struct Action {
    /// -----------------------------------------------------------------------
    /// @name Action Targets
    /// -----------------------------------------------------------------------
    /**
     The "target" is typically the node instance that received the [Node runAction:] message.
     The action will modify the target properties. The target will be set with the 'startWithTarget' method.
     When the 'stop' method is called, target will be set to nil.
     */
    private(set) var target: AnyObject!
    /// -----------------------------------------------------------------------
    /// @name Identifying an Action
    /// -----------------------------------------------------------------------
    /** The action's name. An identifier of the action. */
    var name = ""
    /// -----------------------------------------------------------------------
    /// @name Action Methods Implemented by Subclasses
    /// -----------------------------------------------------------------------
    /**
     *  Return YES if the action has finished.
     *
     *  @return Action completion status
     */
    
    var isDone: Bool {
        return true
    }
    /**
     *  Overridden by subclasses to set up an action before it runs.
     *
     *  @param target Target the action will run on.
     */
    
    func startWithTarget(target: AnyObject) {
    }
    /**
     *  Overriden by subclasses to clean up an action.
     *  Called after the action has finished. Will assign the internal target reference to nil.
     *  Note:
     *  You should never call this method directly.
     *  In stead use: [target stopAction:action]
     */
    
    func stop() {
    }
    /**
     *  Overridden by subclasses to update the target.
     *  Called every frame with the time delta.
     *
     *  Note:
     *  Do not call this method directly. Actions are automatically stepped when used with [Node runAction:].
     *
     *  @param dt Ellapsed interval since last step.
     */
    
    func step(_ dt: Time) {
    }
    /**
     *  Updates the action with normalized value.
     *
     *  For example:
     *  A value of 0.5 indicates that the action is 50% complete.
     *
     *  @param time Normalized action progress.
     */
    
    func update(time: Time) {
    }
}

extension Action: Equatable {
    public static func ==(lhs: Action, rhs: Action) -> Bool {
        return true
    }
}
