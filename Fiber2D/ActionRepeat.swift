//
//  ActionRepeat.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public enum RepeatCount {
    case Times(UInt)
    case Forever
}

extension RepeatCount: Equatable {
    public static func ==(lhs: RepeatCount, rhs: RepeatCount) -> Bool {
        switch (lhs, rhs) {
        case (.Times(let a), .Times(let b)) where a == b: return true
        case (.Forever, .Forever): return true
        default: return false
        }
    }
}


public struct ActionRepeatContainer: ActionContainer {
    public mutating  func start(with target: AnyObject?) {
        if case .Times(let remains) = repeatCount {
            remainingRepeats = remains
        }
        innerContainer.start(with: target)
    }
    
    mutating public func step(dt: Time) {
        innerContainer.step(dt: dt)
        
        if innerContainer.isDone {
            if repeatCount != .Forever {
                remainingRepeats -= 1
            }
            
            guard repeatCount == .Forever || remainingRepeats > 0 else {
                return
            }
            
            innerContainer.start(with: target)
            
            if let c = innerContainer as? Continous {
                let diff = c.elapsed - c.duration
                // to prevent jerk. issue #390, 1247
                innerContainer.step(dt: 0.0)
                innerContainer.step(dt: diff)
            }
        }
    }
    
    public var tag: Int = 0
    weak var target: AnyObject? = nil
    public var isDone: Bool {
        return repeatCount != .Forever && remainingRepeats == 0
    }
    
    public let repeatCount: RepeatCount
    private var remainingRepeats: UInt = 0
    
    private(set) var innerContainer: ActionContainer
    init(action: ActionContainer, repeatCount: RepeatCount) {
        self.innerContainer = action
        self.repeatCount = repeatCount
    }
}

public extension ActionContainer {
    public func repeate(_ count: RepeatCount) -> ActionRepeatContainer {
        return ActionRepeatContainer(action: self, repeatCount: count)
    }
}
