//
//  ActionSpeed.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public struct ActionSpeedContainer: ActionContainer, Continous {
    @inline(__always)
    mutating public func update(state: Float) {
        action.update(state: state)
    }
    
    public mutating  func start(with target: AnyObject?) {
        elapsed = 0
        self.target = target
        action.start(with: target)
    }
    
    public mutating func stop() {
        action.stop()
    }
    
    public mutating func step(dt: Time) {
        elapsed += dt * speed
        
        self.update(state: max(0, // needed for rewind. elapsed could be negative
            min(1, elapsed / max(actionDuration, Float.ulpOfOne)) // division by 0
            )
        )
    }
    
    weak var target: AnyObject? = nil
    public var tag: Int = 0
    public let speed: Float
    public let duration: Time
    private let actionDuration: Time
    private(set) public var elapsed:  Time = 0.0
    
    public var isDone: Bool {
        return elapsed > duration
    }
    
    private(set) var action: ActionContainerFiniteTime
    public init(action: ActionContainerFiniteTime, speed: Float) {
        self.action = action
        self.actionDuration = action.duration
        self.duration = actionDuration / speed
        self.speed = speed
    }
}

extension ActionContainer where Self: FiniteTime {
    public func speed(_ s: Float) -> ActionSpeedContainer {
        return ActionSpeedContainer(action: self, speed: s)
    }
}
