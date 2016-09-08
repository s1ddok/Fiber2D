//
//  Actions.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public protocol Targeted {
    /// -----------------------------------------------------------------------
    /// @name Action Targets
    /// -----------------------------------------------------------------------
    /**
     The "target" is typically the node instance that received the Node.runAction() message.
     The action will modify the target properties. The target will be set with the 'start(with:)' method.
     */
    var target: AnyObject? { get set }
}

// Not all actions support reversing. See individual class references to find out if a certain action does not support reversing.
public protocol Reversable {
    /** @name Reversing an Action */
    /**
     Returns an action that runs in reverse (does the opposite).
     
     @note Not all actions support reversing. See individual action's class references.
     
     @return The reversed action.
     */
    var reversed: Reversable { get }
}

public protocol FiniteTime {
    /** @name Duration */
    /** Duration of the action in seconds. */
    var duration: Time { get }
}
// MARK: Continous
// Protocol that defines time-related properties for an object
/**
 Protocol for actions that (can) have a duration
 */
public protocol Continous: FiniteTime {
    /** @name Elapsed
     *  How many seconds had elapsed since the actions started to run.
     */
    var elapsed: Time { get }
}

public protocol ActionModel {
    /**
     *  Overridden by subclasses to set up an action before it runs.
     *
     *  @param target Target the action will run on.
     */
    mutating func start(with target: AnyObject?)
    
    /**
     *  Called after the action has finished.
     *  Note:
     *  You should never call this method directly.
     *  In stead use: target.stopAction(:)
     */
    mutating func stop()
    
    /**
     *  Updates the action with normalized value.
     *
     *  For example:
     *  A value of 0.5 indicates that the action is 50% complete.
     *
     *  @param state Normalized action progress.
     */
    mutating func update(state: Float)
}

public protocol ActionContainer: Tagged {
    /// -----------------------------------------------------------------------
    /// @name Identifying an Action
    /// -----------------------------------------------------------------------
    /** The action's tag. An identifier of the action. */
    var tag: Int { get set }
    
    /// -----------------------------------------------------------------------
    /// @name Action Methods Implemented by Subclasses
    /// -----------------------------------------------------------------------
    /**
     *  Return YES if the action has finished.
     *
     *  @return Action completion status
     */
    var isDone: Bool { get }
    
    /**
     *  Overridden by subclasses to update the target.
     *  Called every frame with the time delta.
     *
     *  Note:
     *  Do not call this method directly. Actions are automatically stepped when used with [Node runAction:].
     *
     *  @param dt Ellapsed interval since last step.
     */
    mutating func step(dt: Time)
    
    /**
     *  Updates the action with normalized value.
     *
     *  For example:
     *  A value of 0.5 indicates that the action is 50% complete.
     *
     *  @param state Normalized action progress.
     */
    mutating func update(state: Float)
    
    /**
     *  Overridden by subclasses to set up an action before it runs.
     *
     *  @param target Target the action will run on.
     */
    mutating func start(with target: AnyObject?)
    
    /**
     *  Called after the action has finished.
     *  Note:
     *  You should never call this method directly.
     *  In stead use: target.stopAction(:)
     */
    mutating func stop()
}

public typealias ActionContainerFiniteTime = ActionContainer & FiniteTime

// Default implementation
extension ActionModel {
    mutating public func start(with target: AnyObject?) {}
    mutating public func stop() {}
    mutating func update(state: Float) {}
}
extension ActionContainer {
    mutating func start(with target: AnyObject?) {}
    mutating public func stop() {}
}
