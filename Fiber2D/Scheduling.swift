//
//  Scheduling.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public typealias Time = Float

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

// Targets are things that can have update: and fixedUpdate: methods called by the scheduler.
// Scheduled blocks (Timers) can be associated with a target to inherit their priority and paused state.
internal final class ScheduledTarget {
    weak var target: Node?
    var timers: Timer?
    var actions = [ActionContainer]()
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
    
    func add(action: ActionContainer) {
        actions.append(action)
    }
    
    func removeAction(by tag: Int) {
        actions = actions.filter {
            $0.tag != tag
        }
    }
    
    func remove(timer: Timer) {
        timers = timers?.removeRecursive(skip: timer)
    }
    
    init(target: Node) {
        self.target = target
    }
}
