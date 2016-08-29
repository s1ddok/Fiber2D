//
//  Actions.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public class Action {
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
    
    func start(with target: AnyObject) {
        self.target = target
    }
    /**
     *  Overriden by subclasses to clean up an action.
     *  Called after the action has finished. Will assign the internal target reference to nil.
     *  Note:
     *  You should never call this method directly.
     *  In stead use: [target stopAction:action]
     */
    
    func stop() {
        target = nil
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
    
    func step(_ dt: Time) { }
    /**
     *  Updates the action with normalized value.
     *
     *  For example:
     *  A value of 0.5 indicates that the action is 50% complete.
     *
     *  @param time Normalized action progress.
     */
    
    func update(time: Time) { }
}

// MARK: - ActionFiniteTime
/**
 Abstract base class for actions that (can) have a duration or can be reversed.
 
 Not all actions support reversing. See individual class references to find out if a certain action does not support reversing.
 
 ### Subclasses
 
 The ActionFiniteTime class has two additional subclasses (also abstract) which contain more information about actions
 that run instantly (completed within the same frame) vs. actions that run over time (typically taking more than a frame to complete).
 
 - ActionInstant
 - ActionInterval
 
 */
class ActionFiniteTime: Action {
    /** @name Duration */
    /** Duration of the action in seconds. */
    var duration: Time = 0.0
    /** @name Reversing an Action */
    /**
     Returns an action that runs in reverse (does the opposite).
     
     @note Not all actions support reversing. See individual action's class references.
     
     @return The reversed action.
     */
    
    func reverse() -> ActionFiniteTime? {
        return nil
    }
}

/**
 Abstract base class for interval actions. An interval action is an action that performs its task over a certain period of time.
 
 Most ActionInterval actions can be reversed or have their speed altered via the ActionSpeed action.
 
 ### Moving, Rotating, Scaling a Node
 
 - Moving a node along a straight line or curve:
 - ActionMoveBy, ActionMoveTo
 - ActionBezierBy, ActionBezierTo
 - ActionCardinalSplineTo, ActionCardinalSplineBy
 - ActionCatmullRomBy, ActionCatmullRomTo
 - Rotating a node:
 - ActionRotateBy, ActionRotateTo
 - Scaling a node:
 - ActionScaleTo, ActionScaleBy
 
 ### Animating a Node's Visual Properties
 
 - Periodically toggle visible property on/off:
 - ActionBlink
 - Fading a node in/out/to:
 - ActionFadeIn, ActionFadeOut
 - ActionFadeTo
 - Colorizing a node:
 - ActionTintBy, ActionTintTo
 - Skewing a node:
 - ActionSkewTo, ActionSkewBy
 - Animate the sprite frames of a Sprite with Animation:
 - ActionAnimate
 - Animating a ProgressNode:
 - ActionProgressFromTo, ActionProgressTo
 
 ### Repeating and Reversing Actions
 
 - Repeating an action a specific number of times:
 - ActionRepeat
 - Reversing an action (if supported by the action):
 - ActionReverse
 
 ### Creating Sequences of Actions
 
 - Creating a linear sequence of actions:
 - ActionSequence
 - Wait for a given time in a ActionSequence:
 - ActionDelay
 - Spawning parallel running actions in a ActionSequence and continue the sequence when all spawned actions have ended:
 - ActionSpawn
 
 ### Easing the Duration of an Action
 
 - Easing duration of a ActionInterval:
 - ActionEase
 - ActionEaseBackIn, ActionEaseBackInOut, ActionEaseBackOut
 - ActionEaseBounce, ActionEaseBounceIn, ActionEaseBounceInOut, ActionEaseBounceOut
 - ActionEaseElastic, ActionEaseElasticIn, ActionEaseElasticInOut, ActionEaseElasticOut
 - ActionEaseRate, ActionEaseIn, ActionEaseInOut, ActionEaseOut
 - ActionEaseSineIn, ActionEaseSineInOut, ActionEaseSineOut
 
 ### Animating custom float/double Properties
 
 - Tweening any node property (of type float or double):
 - ActionTween
 */
class ActionInterval: ActionFiniteTime {
    var inner: ActionInterval!
    private var firstTick = true
    
    /**
     *  How many seconds had elapsed since the actions started to run.
     */
    private(set) var elapsed = Time()
    /// -----------------------------------------------------------------------
    /// @name Creating a Interval Action
    /// -----------------------------------------------------------------------
    /**
     *  Initializes and returns an action interval object.
     *
     *  @param d Action interval.
     *
     *  @return An initialized ActionInterval Object.
     */
    
    init(duration d: Time) {
        super.init()
        duration = d
        
        if duration == 0.0 {
            duration = FLT_EPSILON
        }
    }
    
    /// -----------------------------------------------------------------------
    /// @name Methods implemented by Subclasses
    /// -----------------------------------------------------------------------
    /**
     *  Returns YES if the action has finished.
     *
     *  @return Action finished status.
     */
    
    override var isDone: Bool {
        return elapsed > duration
    }
    
    override func step(_ dt: Time) {
        if firstTick {
            firstTick = false
            elapsed = 0.0
        } else {
            elapsed += dt
        }
        
        self.update(time: max(0,					// needed for rewind. elapsed could be negative
                          min(1, elapsed /
                                 max(duration,FLT_EPSILON))	// division by 0
            )
        )
    }
    
    override func start(with target: AnyObject) {
        super.start(with: target)
        elapsed = 0.0
        firstTick = true
    }
}

// MARK: - ActionRepeatForever

/**
 *  Repeats an action indefinitely (until stopped).
 *  To repeat the action for a limited number of times use the ActionRepeat action.
 *
 *  @note This action can not be used within a ActionSequence because it is not an ActionInterval action.
 *  However you can use ActionRepeatForever to repeat a ActionSequence.
 */
class ActionRepeatForever: Action {
    // purposefully undocumented: user does not need to aess inner action
    /* Inner action. */
    let innerAction: ActionInterval
    /// -----------------------------------------------------------------------
    /// @name Creating a Repeat Forever Action
    /// -----------------------------------------------------------------------
    /**
     *  Initalizes the repeat forever action.
     *
     *  @param action Action to repeat forever
     *
     *  @return An initialised repeat action object.
     */
    
    init(action: ActionInterval) {
        innerAction = action
    }
}


// MARK: - ActionSpeed
/**
 Allows you to change the speed of an action while the action is running. Useful to simulate slow motion or fast forward effects.
 Can also be used to implement custom easing effects without having to create your own ActionEase subclass.
 
 You will need to keep a reference to the speed action in order to change its `speed` property. It is best to assign
 the speed action to an ivar or property with the `__weak` (ivar) or `weak` (@property) keyword.
 
 For instance:
 
 @implementation YourClass
 {
 __weak ActionSpeed* _speed;
 }
 
 Now you can create an action whose speed you want to be able to alter while the action is running:
 
 id move = [MoveBy actionWithDuration:60 position:p(600, 0)];
 _speed = [ActionSpeed actionWithAction:move speed:1];
 
 The speed factor of 1 will start running the `move` action at its normal speed. Later when you determined that it's
 time to change the speed of the `move` action, just change the `_speed` action's `speed` property:
 
 -(void) update:(Time)deltaTime
 {
 if (slowMotionMode) {
 _speed.speed = 0.2f; // move at one fifth of the regular speed
 } else {
 _speed.speed = 1.0f; // move at regular speed
 }
 }
 
 When the move action has run to completion it will end and thanks to the `__weak` keyword and ARC the `_speed` ivar will
 automatically become `nil`.
 
 @note ActionSpeed can not be added to a ActionSequence because it does not inherit from ActionFiniteTime.
 It can however be used to control the speed of an entire ActionSequence.
 */

