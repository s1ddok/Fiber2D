//
//  Scheduling.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public typealias Time = Float

// Targets are things that can have update: and fixedUpdate: methods called by the scheduler.
// Scheduled blocks (Timers) can be associated with a target to inherit their priority and paused state.
protocol Updatable: class {
    // Used to break ties for scheduled blocks, updated: and fixedUpdate: methods.
    // Targets are sorted by priority so lower priorities are called first.
    // The priority value for a given object should be constant.
    var priority: Int { get }
    func update(delta: Time)
    
    func fixedUpdate(delta: Time)
}

extension Timer {
    func forEach(block: (Timer) -> Void) {
        var timer: Timer? = self
        while timer != nil {
            block(timer!)
            timer = timer!.next
        }
    }
    
    func removeRecursive(skip: Timer) -> Timer? {
        if self === skip {
            return self.next
        } else {
            self.next = self.next?.removeRecursive(skip: skip)
            return self
        }
    }
}

public class ScheduledTarget {
    
    weak var target: Updatable?
    var timers: Timer?
    var actions = [Action]()
    var empty: Bool {
        return timers == nil && !enableUpdates
    }
    var hasActions: Bool {
        return !actions.isEmpty
    }
    var paused = false {
        didSet {
            if paused != oldValue {
                let pause = self.paused
                timers?.forEach { $0.paused = pause }
            }
        }
    }
    var enableUpdates = false
    
    func invalidateTimers() {
        timers?.forEach { $0.invalidate() }
    }
    
    func add(action: Action) {
        actions.append(action)
    }
    
    func remove(action: Action) {
        if let idx = actions.index(of: action) {
            actions.remove(at: idx)
        }
    }
    
    func remove(timer: Timer) {
        timers = timers?.removeRecursive(skip: timer)
    }
    
    init(target: Updatable) {
        self.target = target
    }
}
