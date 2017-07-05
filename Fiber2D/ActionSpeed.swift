//
//  ActionSpeed.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public struct ActionSpeedContainer: ActionContainer, Continous {

    mutating public func update(with target: Node, state: Float) {
        action.update(with: target, state: state)
    }
    
    public mutating func start(with target: Node) {
        elapsed = 0
        action.start(with: target)
    }
    
    public mutating func stop(with target: Node) {
        action.stop(with: target)
    }
    
    public mutating func step(with target: Node, dt: Time) {
        elapsed += dt * speed
        
        self.update(with: target, state: max(0, // needed for rewind. elapsed could be negative
            min(1, elapsed / max(actionDuration, Float.ulpOfOne)) // division by 0
            )
        )
    }
    
    weak var target: Node?
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

public extension ActionContainer where Self: FiniteTime {
    public func speed(_ s: Float) -> ActionSpeedContainer {
        return ActionSpeedContainer(action: self, speed: s)
    }
}
