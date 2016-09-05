//
//  ActionRepeat.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

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

public struct ActionRepeatContainer: ActionContainer {
    public mutating func update(state: Float) {
        innerContainer.update(state: state * Float(repeatCount))
    }
    
    public mutating  func start(with target: AnyObject?) {
        self.target = target
        self.remainingRepeats = repeatCount
        innerContainer.start(with: target)
    }
    
    mutating public func step(dt: Time) {
        innerContainer.step(dt: dt)
        
        if innerContainer.isDone {
            remainingRepeats -= 1
            
            guard remainingRepeats > 0 else {
                return
            }
            
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
        return remainingRepeats == 0
    }
    
    public let repeatCount: UInt
    private var remainingRepeats: UInt = 0
    
    private(set) var innerContainer: ActionContainer
    init(action: ActionContainer, repeatCount: UInt) {
        self.innerContainer = action
        self.repeatCount = repeatCount
    
        if !(action is FiniteTime) {
            assertionFailure("ERROR: You can't repeat infinite action")
        }
    }
}

extension ActionRepeatContainer: FiniteTime {
    public var duration: Time {
        let mp = Float(repeatCount)
        
        return (innerContainer as! FiniteTime).duration * mp
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
