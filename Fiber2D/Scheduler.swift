//
//  Scheduler.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

private class MockUpdatable: Updatable {
    var priority: Int {
        return Int.min
    }
    func update(delta: Time) {}
    func fixedUpdate(delta: Time) {}
}
/**
 Scheduler is responsible for triggering scheduled callbacks. All scheduled and timed events should use this class, rather than NSTimer.
 Generally, you interface with the scheduler by using the "schedule"/"scheduleBlock" methods in Node. You may need to aess Scheduler
 in order to aess read-only time properties or to adjust the time scale.
 */
class Scheduler {
    func update(dt: Time) {
    }
    /* Modifies the time of all scheduled callbacks.
     You can use this property to create a 'slow motion' or 'fast forward' effect.
     Default is 1.0. To create a 'slow motion' effect, use values below 1.0.
     To create a 'fast forward' effect, use values higher than 1.0.
     @warning It will affect EVERY scheduled selector / action.
     */
    var timeScale: Time = 1.0
    /**
     Current time the scheduler is calling a block for.
     */
    internal(set) var currentTime: Time = 0.0
    /**
     Time of the most recent update: calls.
     */
    internal(set) var lastUpdateTime: Time = 0.0
    /**
     Time of the most recent fixedUpdate: calls.
     */
    private(set) var lastFixedUpdateTime: Time = 0.0
    /**
     Maximum allowed time step.
     If the CPU can't keep up with the game, time will slow down.
     */
    var maxTimeStep: Time = 1.0 / 10.0
    /**
     The time between fixedUpdate: calls.
     */
    var fixedUpdateInterval: Time {
        get {
            return fixedUpdateTimer.repeatInterval
        }
        set {
            fixedUpdateTimer.repeatInterval = newValue
        }
    }
    
    var heap = [Timer]()
    var scheduledTargets = [ScheduledTarget]()
    var updatableTargets = [ScheduledTarget]()
    var actionTargets    = [ScheduledTarget]()
    internal var updatableTargetsNeedSorting = true
    var fixedUpdateTimer: Timer!
    private let mock = MockUpdatable()
    var actionsRunInFixedMode = false
    
    init() {
        fixedUpdateTimer = schedule(block: { [unowned self](timer:Timer) in
            if timer.invokeTime > 0.0 {
                for t in self.updatableTargets {
                    t.target?.fixedUpdate(delta: timer.repeatInterval)
                }
                
                if self.actionsRunInFixedMode {
                    self.updateActions(timer.repeatInterval)
                }
                
                self.lastFixedUpdateTime = timer.invokeTime
            }
            }, for: mock, withDelay: 0)
        fixedUpdateTimer.repeatCount = TIMER_REPEAT_COUNT_FOREVER
        fixedUpdateTimer.repeatInterval = Time(CCSetup.shared().fixedUpdateInterval)
    }
}

// MARK: Update
extension Scheduler {
    internal func schedule(timer: Timer) {
        heap.append(timer)
        timer.scheduled = true
    }
    
    internal func update(to targetTime: Time) {
        assert(targetTime >= currentTime, "Cannot step to a time in the past")
        
        heap.sort()
        
        for timer in heap {
            let invokeTime = timer.invokeTimeInternal
            
            if invokeTime > targetTime {
                break;
            } else {
                timer.scheduled = false
            }
            
            currentTime = invokeTime
            
            guard !timer.paused else {
                continue
            }
            
            if timer.requiresDelay {
                timer.apply(pauseDelay: currentTime)
                schedule(timer: timer)
            } else {
                timer.block?(timer)
                
                if timer.repeatCount > 0 {
                    if timer.repeatCount < TIMER_REPEAT_COUNT_FOREVER {
                        timer.repeatCount -= 1
                    }
                    
                    timer.deltaTime = timer.repeatInterval
                    let delay = timer.deltaTime
                    timer.invokeTimeInternal += delay
                    
                    assert(delay > 0.0, "Rescheduling a timer with a repeat interval of 0 will cause an infinite loop.")
                    self.schedule(timer: timer)
                } else {
                    guard let scheduledTarget = timer.scheduledTarget else {
                        continue
                    }
                    scheduledTarget.remove(timer: timer)
                    
                    if scheduledTarget.empty {
                        scheduledTargets.removeObject(scheduledTarget.target!)
                    }
                    
                    timer.invalidate()
                }
            }
        }
    }
    
    internal func update(_ dt: Time) {
        let clampedDelta = min(dt*timeScale, maxTimeStep)
        
        update(to: currentTime + clampedDelta)
        
        for t in updatableTargets {
            if !t.paused {
                t.target?.update(delta: clampedDelta)
            }
        }
        
        if !self.actionsRunInFixedMode {
            updateActions(dt)
        }
        
        lastUpdateTime = currentTime
    }
    
    internal func updateActions(_ dt: Time) {
        actionTargets = actionTargets.filter{
            let st = $0
            
            guard !st.paused else {
                return st.hasActions
            }
            
            st.actions = st.actions.filter {
                let action = $0
                action.step(dt)
                
                if action.isDone {
                    action.stop()
                }
                
                return !action.isDone
            }
            
            return st.hasActions
        }
    }
}

// MARK: Getters
extension Scheduler {
    
    func scheduledTarget(for target: Updatable, insert: Bool) -> ScheduledTarget? {
        var scheduledTarget = scheduledTargets.first {
            $0.target === target
        }
        
        if scheduledTarget == nil && insert {
            scheduledTarget = ScheduledTarget(target: target)
            scheduledTargets.append(scheduledTarget!)
            // New targets are implicitly paused.
            scheduledTarget!.paused = true
        }
        
        return scheduledTarget
    }
    
    func schedule(block: TimerBlock, for target: Updatable, withDelay delay: Time) -> Timer {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        let timer = Timer(delay: delay, scheduler: self, scheduledTarget: scheduledTarget, block: block)
        self.schedule(timer: timer)
        timer.next = scheduledTarget.timers
        scheduledTarget.timers = timer
        return timer
    }
    
    func schedule(target: Updatable) {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        // Don't schedule something more than once.
        if !scheduledTarget.enableUpdates {
            scheduledTarget.enableUpdates = true
            
            updatableTargets.append(scheduledTarget)
            updatableTargetsNeedSorting = true
        }
    }
    
    func unschedule(target: Updatable) {
        if let scheduledTarget = self.scheduledTarget(for: target, insert: false) {
            // Remove the update methods if they are scheduled
            if scheduledTarget.enableUpdates {
                updatableTargets.removeObject(scheduledTarget)
            }
            if scheduledTarget.hasActions {
                actionTargets.removeObject(scheduledTarget)
            }
            scheduledTarget.invalidateTimers()
            scheduledTargets.removeObject(scheduledTarget)
        }
    }
    
    func isTargetScheduled(target: Updatable) -> Bool {
        return self.scheduledTarget(for: target, insert: false) != nil
    }
    
    func setPaused(paused: Bool, target: Updatable) {
        let scheduledTarget = self.scheduledTarget(for: target, insert: false)!
        scheduledTarget.paused = paused
    }
    
    func isTargetPaused(target: Updatable) -> Bool {
        let scheduledTarget = self.scheduledTarget(for: target, insert: false)!
        return scheduledTarget.paused
    }
    
    func timersForTarget(target: Updatable) -> [Timer] {
        guard let scheduledTarget = self.scheduledTarget(for: target, insert: false) else {
            return []
        }
        var arr = [Timer]()
        var timer = scheduledTarget.timers
        while timer != nil {
            if !timer!.invalid {
                arr.append(timer!)
            }
            timer = timer!.next
        }
        return arr
    }
}

// MARK: Scheduling Actions
extension Scheduler {
    func add(action: Action, target: Updatable, paused: Bool) {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        scheduledTarget.paused = paused
        if scheduledTarget.hasActions {
            //assert(!scheduledTarget.actions.contains(action), "Action already running on this target.")
        } else {
            // This is the first action that has been scheduled for this target.
            // It needs to be added to the list of targets with actions.
            actionTargets.append(scheduledTarget)
        }
        scheduledTarget.add(action: action)
        action.start(with: target)
    }
    
    func remove(action: Action, from target: Updatable) {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        scheduledTarget.actions.removeObject(action)
    }
    
    func removeAllActions(from target: Updatable) {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        scheduledTarget.actions = []
        actionTargets.removeObject(scheduledTarget)
    }
    
    func removeAction(by name: String, target: Updatable) {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        scheduledTarget.actions = scheduledTarget.actions.filter {
            return $0.name != name
        }

        guard scheduledTarget.hasActions else {
            return
        }
        
        actionTargets.removeObject(scheduledTarget)
    }
    
    func getAction(by name: String, target: Updatable) -> Action? {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        for action: Action in scheduledTarget.actions {
            if (action.name == name) {
                return action
            }
        }
        return nil
    }
    
    func actions(for target: Updatable) -> [Action] {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        return scheduledTarget.actions
    }
}

