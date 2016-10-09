//
//  ActionRepeat.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

/**
 *  Repeats an action indefinitely (until stopped).
 *  To repeat the action for a limited number of times use the ActionRepeat action.
 *
 *  @note This action can not be used within a ActionSequence because it is not an FiniteTime action.
 *  However you can use ActionRepeatForever to repeat a ActionSequence.
 */
public struct ActionRepeatForeverContainer: ActionContainer {
    public mutating func update(state: Float) { }
    
    public mutating func start(with target: AnyObject?) {
        self.target = target
        innerContainer.start(with: target)
    }
    
    mutating public func step(dt: Time) {
        innerContainer.step(dt: dt)
        
        if innerContainer.isDone {
            if let c = innerContainer as? Continous {
                let diff = c.elapsed - c.duration
                
                defer {
                    // to prevent jerk. issue #390, 1247
                    innerContainer.step(dt: 0.0)
                    innerContainer.step(dt: diff)
                }
            }
            
            innerContainer.start(with: target)
        }
    }
    
    public var tag: Int = 0
    weak var target: AnyObject? = nil
    public var isDone: Bool {
        return false
    }
    
    private(set) var innerContainer: ActionContainer
    init(action: ActionContainer) {
        self.innerContainer = action
        
        if !(action is FiniteTime) {
            assertionFailure("ERROR: You can't repeat infinite action")
        }
    }
}

public struct ActionRepeatContainer: ActionContainer, FiniteTime {
    public mutating func update(state: Float) {
        // issue #80. Instead of hooking step:, hook update: since it can be called by any
        // container action like Repeat, Sequence, Ease, etc..
        let dt = state
        if dt >= nextDt {
            while dt >= nextDt && remainingRepeats > 0 {
                innerContainer.update(state: 1.0)
                remainingRepeats -= 1
                
                innerContainer.stop()
                innerContainer.start(with: target)
                self.nextDt = Float(Int(repeatCount - remainingRepeats) + 1) / Float(repeatCount)
            }
            // fix for issue #1288, incorrect end value of repeat
            if dt ~= 1.0 && remainingRepeats > 0 {
                innerContainer.update(state: 1.0)
                remainingRepeats -= 1
            }
            
            guard icDuration > 0 else {
                return
            }
            if remainingRepeats == 0 {
                innerContainer.stop()
            } else {
                // issue #390 prevent jerk, use right update
                innerContainer.update(state: dt - (nextDt - 1.0 / Float(repeatCount)))
            }
        } else {
            guard icDuration > 0 else {
                return
            }
            let clampedState = (dt * Float(repeatCount)).truncatingRemainder(dividingBy: 1.0)
            innerContainer.update(state: clampedState)
        }
        
    }
    
    public mutating  func start(with target: AnyObject?) {
        self.elapsed = 0
        self.target = target
        self.remainingRepeats = repeatCount
        self.nextDt = 1.0 / Float(repeatCount)
        innerContainer.start(with: target)
    }

    mutating public func step(dt: Time) {
        guard icDuration > 0 else {
            innerContainer.start(with: target)
            innerContainer.update(state: 1.0)
            innerContainer.stop()
            remainingRepeats -= 1
            return
        }
        
        elapsed += dt
        self.update(state: max(0, // needed for rewind. elapsed could be negative
            min(1, elapsed / max(duration, Float.ulpOfOne)) // division by 0
            )
        )
    }
    
    public var tag: Int = 0
    weak var target: AnyObject? = nil
    public var isDone: Bool {
        return remainingRepeats == 0
    }
    
    public let repeatCount: UInt
    private var remainingRepeats: UInt = 0
    private var nextDt: Float = 0.0
    
    private let icDuration: Time
    public  let duration: Time
    private var elapsed: Time = 0.0
    
    private(set) var innerContainer: ActionContainerFiniteTime
    init(action: ActionContainerFiniteTime, repeatCount: UInt) {
        self.innerContainer = action
        self.repeatCount = repeatCount
    
        self.icDuration = action.duration
        self.duration = Float(repeatCount) * icDuration
    }
}

public extension ActionContainer where Self: FiniteTime  {
    public func `repeat`(times: UInt) -> ActionRepeatContainer {
        return ActionRepeatContainer(action: self, repeatCount: times)
    }
    
    public var repeatForever: ActionRepeatForeverContainer {
        return ActionRepeatForeverContainer(action: self)
    }
}
