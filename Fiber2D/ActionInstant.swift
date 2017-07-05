//
//  ActionInstant.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 03.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public struct ActionInstantContainer: ActionContainer {
    
    mutating public func update(with target: Node, state: Float) {
        action.update(with: target, state: 1.0)
    }
    
    mutating public func start(with target: Node) {
        action.start(with: target)
    }
    
    mutating public func stop(with target: Node) {
        action.stop(with: target)
    }
    
    mutating public func step(with target: Node, dt: Time) {
        self.update(with: target, state: 1.0)
    }
    
    public var tag: Int = 0
    public var isDone: Bool {
        return true
    }
        
    private(set) var action: ActionModel
    init(action: ActionModel) {
        self.action = action
    }
}

public extension ActionModel {
    public var instantly: ActionInstantContainer {
        return ActionInstantContainer(action: self)
    }
}

extension ActionInstantContainer: FiniteTime {
    public var duration: Time {
        return 0.0
    }
}
    
