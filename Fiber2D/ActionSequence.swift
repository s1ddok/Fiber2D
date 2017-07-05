//
//  ActionSequenceContainer.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public struct ActionSequenceContainer: ActionContainer, Continous {

    mutating public func update(with target: Node, state: Float) {
        let t = state
        var found = 0
        var new_t: Float = 0.0
        if t < split {
            // action[0]
            found = 0
            if split != 0 {
                new_t = t / split
            }
            else {
                new_t = 1
            }
        } else {
            // action[1]
            found = 1
            if split == 1 {
                new_t = 1
            }
            else {
                new_t = (t - split) / (1 - split)
            }
        }
        if found == 1 {
            if last == -1 {
                // action[0] was skipped, execute it.
                actions[0].start(with: target)
                actions[0].update(with: target, state: 1.0)
                actions[0].stop(with: target)
            }
            else if last == 0 {
                // switching to action 1. stop action 0.
                actions[0].update(with: target, state: 1.0)
                actions[0].stop(with: target)
            }
        } else if found == 0 && last == 1 {
            // Reverse mode ?
            // XXX: Bug. this case doesn't contemplate when _last==-1, found=0 and in "reverse mode"
            // since it will require a hack to know if an action is on reverse mode or not.
            // "step" should be overriden, and the "reverseMode" value propagated to inner Sequences.
            actions[1].update(with: target, state: 0)
            actions[1].stop(with: target)
        }
        
        // Last action found and it is done.
        if found == last && actions[found].isDone {
            return
        }
        // New action. Start it.
        if found != last {
            actions[found].start(with: target)
        }
        actions[found].update(with: target, state: new_t)
        self.last = found
    }
    
    public mutating func start(with target: Node) {
        elapsed = 0
        self.split = actions[0].duration / max(duration, Float.ulpOfOne)
        self.last = -1
    }
    
    public mutating func stop(with target: Node) {
        // Issue #1305
        if last != -1 {
            actions[last].stop(with: target)
        }
    }
    
    public mutating func step(with target: Node, dt: Time) {
        elapsed += dt
        
        self.update(with: target, state: max(0, // needed for rewind. elapsed could be negative
            min(1, elapsed / max(duration, Float.ulpOfOne)) // division by 0
            )
        )
    }
    
    public var tag: Int = 0
    private(set) public var duration: Time = 0.0
    private(set) public var elapsed: Time = 0.0
    
    public var isDone: Bool {
        return elapsed > duration
    }
    
    private(set) var actions: [ActionContainerFiniteTime] = []

    private var split: Float = 0.0
    private var last = -1

    init(first: ActionContainerFiniteTime, second: ActionContainerFiniteTime) {
        actions = [first, second]
        // Force unwrap because it won't work otherwise anyways
        duration = first.duration + second.duration
    }
}

/*extension ActionSequenceContainer {
    init(actions: ActionContainer...) {
        guard actions.count > 2 else {
            assertionFailure("ERROR: Sequence must contain at least 2 actions")
            return
        }
        
        let first = actions.first!
        var second: ActionContainer = actions[1]
 
        for i in 2..<actions.count {
            second = ActionSequenceContainer(first: second, second: actions[i])
        }
        
        self.init(first: first, second: second)
    }
}*/

public extension ActionContainer where Self: FiniteTime {
    public func then(_ next: ActionContainerFiniteTime) -> ActionSequenceContainer {
        return ActionSequenceContainer(first: self, second: next)
    }
}
