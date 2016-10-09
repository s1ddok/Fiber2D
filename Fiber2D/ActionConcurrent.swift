//
//  ActionConcurrent.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public struct ActionConcurrent: ActionModel {
    
    @inline(__always)
    mutating public func update(state: Float) {
        first.update(state: state)
        second.update(state: state)

    }
    
    public mutating func start(with target: AnyObject?) {
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

public struct ActionConcurrentContainer: ActionContainer, Continous {
    
    @inline(__always)
    mutating public func update(state: Float) {
        if state <= firstDuration {
            first.update(state: state)
        }
        if state <= secondDuration {
            second.update(state: state)
        }
    }
    
    public mutating  func start(with target: AnyObject?) {
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
    private(set) public var elapsed:  Time = 0.0
    
    public var isDone: Bool {
        return elapsed > duration
    }
    
    private(set) var first: ActionContainerFiniteTime
    private(set) var second: ActionContainerFiniteTime
    
    public init(first: ActionContainerFiniteTime, second: ActionContainerFiniteTime) {
        self.first = first
        self.second = second
        
        let firstDuration = first.duration
        let secondDuration = first.duration
        self.duration = max(firstDuration, secondDuration)
        
        self.firstDuration = firstDuration / duration
        self.secondDuration = secondDuration / duration
    }
    
}

extension ActionContainer where Self: FiniteTime {
    func and(_ action: ActionContainerFiniteTime) -> ActionConcurrentContainer {
        return ActionConcurrentContainer(first: self, second: action)
    }
}

extension ActionModel {
    func and(_ action: ActionModel) -> ActionConcurrent {
        return ActionConcurrent(first: self, second: action)
    }
}
