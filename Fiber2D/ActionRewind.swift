//
//  ActionRewind.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 06.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

// This will not be actually very usable
// Since we can't basically rewind action like MoveTo, 
// since we don't the start point
// Maybe we should consider introducing "Rewindable" protocol,
// but as of Action are chosed to be value types, that will be a bit hacky
// You can't make a lot of use from it, but maybe there are some special cases
public struct ActionRewindContainer: ActionContainer, Continous {
    @inline(__always)
    mutating public func update(state: Float) {
        action.update(state: 1.0 - state)
    }
    
    public mutating  func start(with target: AnyObject?) {
        elapsed = 0
        action.start(with: target)
    }
    
    public mutating func stop() {
        action.stop()
    }
    
    public mutating func step(dt: Time) {
        elapsed += dt
        
        self.update(state: max(0, // needed for rewind. elapsed could be negative
            min(1, elapsed / max(duration, Float.ulpOfOne)) // division by 0
            )
        )
    }
    
    public var tag: Int = 0
    public let duration: Time
    private(set) public var elapsed:  Time = 0.0
    
    public var isDone: Bool {
        return elapsed > duration
    }
    
    private(set) public var action: ActionContainerFiniteTime
    public init(action: ActionContainerFiniteTime) {
        self.action = action
        self.duration = action.duration
    }
}

public extension ActionContainer where Self: FiniteTime {
    /**
     *   This will return ActionRewindContainer for a given ActionContainer
     *   Passed value must conform to FiniteTime protocol
     *
     *   @see FiniteTime
     */
    public var rewinded: ActionRewindContainer {
        return ActionRewindContainer(action: self)
    }
}
