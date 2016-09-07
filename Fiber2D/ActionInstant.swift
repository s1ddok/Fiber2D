//
//  ActionInstant.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 03.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public struct ActionInstantContainer: ActionContainer {
    
    @inline(__always)
    mutating public func update(state: Float) {
        action.update(state: 1.0)
    }
    
    mutating public func start(with target: AnyObject?) {
        action.start(with: target)
    }
    
    mutating public func stop() {
        action.stop()
    }
    
    mutating public func step(dt: Time) {
        self.update(state: 1.0)
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
    
