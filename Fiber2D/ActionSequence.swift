//
//  ActionSequenceContainer.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public struct ActionSequenceContainer: ActionContainer, Continous {
    @inline(__always)
    mutating public func update(state: Float) {
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
        }
        else {
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
                actions[0].update(state: 1.0)
                actions[0].stop()
            }
            else if last == 0 {
                // switching to action 1. stop action 0.
                actions[0].update(state: 1.0)
                actions[0].stop()
            }
        }
        else if found == 0 && last == 1 {
            // Reverse mode ?
            // XXX: Bug. this case doesn't contemplate when _last==-1, found=0 and in "reverse mode"
            // since it will require a hack to know if an action is on reverse mode or not.
            // "step" should be overriden, and the "reverseMode" value propagated to inner Sequences.
            actions[1].update(state: 0)
            actions[1].stop()
        }
        
        // Last action found and it is done.
        if found == last && actions[found].isDone {
            return
        }
        // New action. Start it.
        if found != last {
            actions[found].start(with: target)
        }
        actions[found].update(state: new_t)
        self.last = found
    }
    
    public mutating func start(with target: AnyObject?) {
        elapsed = 0
        self.target = target
        self.split = actions[0].duration / max(duration, Float.ulpOfOne)
        self.last = -1
    }
    
    public mutating func stop() {
        // Issue #1305
        if last != -1 {
            actions[last].stop()
        }
        
        target = nil
    }
    
    public mutating func step(dt: Time) {
        elapsed += dt
        
        self.update(state: max(0, // needed for rewind. elapsed could be negative
            min(1, elapsed / max(duration, Float.ulpOfOne)) // division by 0
            )
        )
    }
    
    weak var target: AnyObject? = nil
    public var tag: Int = 0
    private(set) public var duration: Time = 0.0
    private(set) public var elapsed:  Time = 0.0
    
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

extension ActionContainer where Self: FiniteTime {
    public func then(_ next: ActionContainerFiniteTime) -> ActionSequenceContainer {
        return ActionSequenceContainer(first: self, second: next)
    }
}
