//
//  ActionConcurrent.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/**
 * This model can be used to combine multiple models to treat them as one.
 */
public struct ActionConcurrent: ActionModel {
    
    @inline(__always)
    mutating public func update(state: Float) {
        first.update(state: state)
        second.update(state: state)

    }
    
    public mutating func start(with target: Node) {
        first.start(with: target)
        second.start(with: target)
    }
    
    public mutating func stop() {
        first.stop()
        second.stop()
    }
    
    public var tag: Int = 0
    
    private(set) var first: ActionModel
    private(set) var second: ActionModel
    
    public init(first: ActionModel, second: ActionModel) {
        self.first = first
        self.second = second
    }
}

/** This action can be used in a ActionSequence to allow the sequence to spawn 2 or more actions that run in parallel to the sequence.
 
 Usage example with a sequence, assuming actionX and spawnActionX are previously declared, assigned and are FiniteTime:
 
 let spawn = spawnAction1.and(spawnAction2)
 let sequence = action1.then(spawn).then(action2)
 self.run(action:sequence)
 
 This will run action1 to completion. Then spawnAction1 and spawnAction2 will run in parallel to completion. Then action4 will run after
 both spawnAction1 and spawnAction2 have run to completion. Note that if spawnAction1 and spawnAction2 have different duration, the duration
 of the longer running action will become the duration of the spawn action.
 
 @note To generally run actions in parallel you can simply call run(action:) for each action rather than creating a sequence with a spawn action.
 For example, this suffices to run two actions in parallel:
 
 self.run(action:action1)
 self.run(action:action2)
 
 @note It is not meaningful to use ActionCuncurrentContainer with just one action.
 */
public struct ActionConcurrentContainer: ActionContainer, Continous {
    
    mutating public func update(state: Float) {
        first.update(state: state)
        second.update(state: state)
    }
    
    public mutating func start(with target: Node) {
        elapsed = 0
        first.start(with: target)
        second.start(with: target)
    }
    
    public mutating func stop() {
        first.stop()
        second.stop()
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
    private let firstDuration: Time
    private let secondDuration: Time
    private(set) public var elapsed: Time = 0.0
    
    public var isDone: Bool {
        return elapsed > duration
    }
    
    private(set) var first:  ActionContainerFiniteTime
    private(set) var second: ActionContainerFiniteTime
    
    public init(first: ActionContainerFiniteTime, second: ActionContainerFiniteTime) {
        let firstDuration = first.duration
        let secondDuration = second.duration
        self.duration = max(firstDuration, secondDuration)
        
        self.firstDuration = firstDuration / duration
        self.secondDuration = secondDuration / duration
        
        if firstDuration > secondDuration {
            self.first  = first
            self.second = second.then(ActionWait(for: firstDuration - secondDuration))
        } else if secondDuration < firstDuration {
            self.first  = first.then(ActionWait(for: secondDuration - firstDuration))
            self.second = second
        } else {
            self.first = first
            self.second = second
        }
    }
    
}

public extension ActionContainer where Self: FiniteTime {
    public func and(_ action: ActionContainerFiniteTime) -> ActionConcurrentContainer {
        return ActionConcurrentContainer(first: self, second: action)
    }
}

public extension ActionModel {
    public func and(_ action: ActionModel) -> ActionConcurrent {
        return ActionConcurrent(first: self, second: action)
    }
}
