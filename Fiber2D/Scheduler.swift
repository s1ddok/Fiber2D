//
//  Scheduler.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

private class MockNode: Node {
    override var priority: Int {
        get { return Int.min }
        set { }
    }
}

internal struct UnownedContainer<T> where T: AnyObject {
    unowned var value : T
    
    init(_ value: T) {
        self.value = value
    }
}

/**
 Scheduler is responsible for triggering scheduled callbacks. All scheduled and timed events should use this class, rather than NSTimer.
 Generally, you interface with the scheduler by using the "schedule"/"scheduleBlock" methods in Node. You may need to aess Scheduler
 in order to aess read-only time properties or to adjust the time scale.
 */
public final class Scheduler {
    /** Modifies the time of all scheduled callbacks.
     You can use this property to create a 'slow motion' or 'fast forward' effect.
     Default is 1.0. To create a 'slow motion' effect, use values below 1.0.
     To create a 'fast forward' effect, use values higher than 1.0.
     @warning It will affect EVERY scheduled selector / action.
     */
    public var timeScale: Time = 1.0
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
    
    internal var heap = [Timer]()
    var scheduledTargets      = [ScheduledTarget]()
    var updatableTargets      = [Updatable      & Pausable]()
    var fixedUpdatableTargets = [FixedUpdatable & Pausable]()
    var actionTargets         = [UnownedContainer<ScheduledTarget>]()
    internal var updatableTargetsNeedSorting = true
    internal var fixedUpdatableTargetsNeedSorting = true
    var fixedUpdateTimer: Timer!
    private let mock = MockNode()
    public var actionsRunInFixedMode = false
    
    init() {
        fixedUpdateTimer = schedule(block: { [unowned self](timer:Timer) in
            if timer.invokeTime > 0.0 {
                if self.fixedUpdatableTargetsNeedSorting {
                    self.fixedUpdatableTargets.sort { $0.priority < $1.priority }
                    self.fixedUpdatableTargetsNeedSorting = false
                }
                for t in self.fixedUpdatableTargets {
                    t.fixedUpdate(delta: timer.repeatInterval)
                }
                
                if self.actionsRunInFixedMode {
                    self.updateActions(timer.repeatInterval)
                }
                
                self.lastFixedUpdateTime = timer.invokeTime
            }
            }, for: mock, withDelay: 0)
        fixedUpdateTimer.repeatCount = TIMER_REPEAT_COUNT_FOREVER
        fixedUpdateTimer.repeatInterval = Time(Setup.shared.fixedUpdateInterval)
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
        
        while heap.count > 0 {
            let timer = heap.first!
            
            let invokeTime = timer.invokeTimeInternal
            
            if invokeTime > targetTime {
                break;
            } else {
                heap.removeFirst()
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
                        scheduledTargets.removeObject(scheduledTarget)
                    }
                    
                    timer.invalidate()
                }
            }
        }
        currentTime = targetTime
    }
    
    internal func update(_ dt: Time) {
        let clampedDelta = min(dt*timeScale, maxTimeStep)
        
        update(to: currentTime + clampedDelta)
        
        if self.updatableTargetsNeedSorting {
            self.updatableTargets.sort { $0.priority < $1.priority }
            self.updatableTargetsNeedSorting = false
        }
        
        for t in updatableTargets {
            if !t.paused {
                t.update(delta: clampedDelta)
            }
        }
        
        if !self.actionsRunInFixedMode {
            updateActions(dt)
        }
        
        lastUpdateTime = currentTime
    }
    
    internal func updateActions(_ dt: Time) {
        actionTargets = actionTargets.filter {
            let st = $0.value
            
            guard !st.paused else {
                return st.hasActions
            }
            
            for i in 0..<st.actions.count {
                st.actions[i].step(dt: dt)
                
                if st.actions[i].isDone {
                    st.actions[i].stop()
                }
            }
            
            st.actions = st.actions.filter {
                return !$0.isDone
            }
            
            return st.hasActions
        }
    }
}

// MARK: Getters
extension Scheduler {
    
    func scheduledTarget(for target: Node, insert: Bool) -> ScheduledTarget? {
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
    
    func schedule(block: @escaping TimerBlock, for target: Node, withDelay delay: Time) -> Timer {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        let timer = Timer(delay: delay, scheduler: self, scheduledTarget: scheduledTarget, block: block)
        self.schedule(timer: timer)
        timer.next = scheduledTarget.timers
        scheduledTarget.timers = timer
        return timer
    }
    
    func schedule(target: Node) {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        // Don't schedule something more than once.
        if !scheduledTarget.enableUpdates {
            scheduledTarget.enableUpdates = true
            
            if target.updatableComponents.count > 0 {
                schedule(updatable: target)
            }
            
            if target.fixedUpdatableComponents.count > 0 {
                schedule(fixedUpdatable: target)
            }
        }
    }
    
    func unscheduleUpdates(from target: Node) {
        guard let scheduledTarget = self.scheduledTarget(for: target, insert: false) else {
            return
        }
        
        scheduledTarget.enableUpdates = false
        let target = scheduledTarget.target!
        
        if target.updatableComponents.count > 0 {
            unschedule(updatable: target)
        }
        
        if target.fixedUpdatableComponents.count > 0 {
            unschedule(fixedUpdatable: target)
        }

    }
    func unschedule(target: Node) {
        if let scheduledTarget = self.scheduledTarget(for: target, insert: false) {
            // Remove the update methods if they are scheduled
            if scheduledTarget.enableUpdates {
                unschedule(updatable: scheduledTarget.target!)
                unschedule(fixedUpdatable: scheduledTarget.target!)
            }
            if scheduledTarget.hasActions {
                actionTargets.remove(at: actionTargets.index { $0.value === scheduledTarget }!)
            }
            scheduledTarget.invalidateTimers()
            scheduledTargets.removeObject(scheduledTarget)
        }
    }
    
    func isTargetScheduled(target: Node) -> Bool {
        return self.scheduledTarget(for: target, insert: false) != nil
    }
    
    func setPaused(paused: Bool, target: Node) {
        let scheduledTarget = self.scheduledTarget(for: target, insert: false)!
        scheduledTarget.paused = paused
    }
    
    func isTargetPaused(target: Node) -> Bool {
        let scheduledTarget = self.scheduledTarget(for: target, insert: false)!
        return scheduledTarget.paused
    }
    
    func timersForTarget(target: Node) -> [Timer] {
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
    func add(action: ActionContainer, target: Node, paused: Bool) {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        scheduledTarget.paused = paused
        if scheduledTarget.hasActions {
            //assert(!scheduledTarget.actions.contains(action), "Action already running on this target.")
        } else {
            // This is the first action that has been scheduled for this target.
            // It needs to be added to the list of targets with actions.
            actionTargets.append(UnownedContainer(scheduledTarget))
        }
        scheduledTarget.add(action: action)
        scheduledTarget.actions[scheduledTarget.actions.count - 1].start(with: target)
    }
    
    func removeAllActions(from target: Node) {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        scheduledTarget.actions = []
        if let idx = actionTargets.index(where: { $0.value === scheduledTarget }) {
            actionTargets.remove(at: idx)
        }
    }
    
    func removeAction(by tag: Int, target: Node) {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        scheduledTarget.actions = scheduledTarget.actions.filter {
            return $0.tag != tag
        }

        guard scheduledTarget.hasActions else {
            return
        }
        
        actionTargets.remove(at: actionTargets.index { $0.value === scheduledTarget }!)
    }
    
    func getAction(by tag: Int, target: Node) -> ActionContainer? {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        for action: ActionContainer in scheduledTarget.actions {
            if (action.tag == tag) {
                return action
            }
        }
        return nil
    }
    
    func actions(for target: Node) -> [ActionContainer] {
        let scheduledTarget = self.scheduledTarget(for: target, insert: true)!
        return scheduledTarget.actions
    }
}


public extension Scheduler {
    public func schedule(updatable: Updatable & Pausable) {
        updatableTargets.append(updatable)
        updatableTargetsNeedSorting = true
    }
    
    public func unschedule(updatable: Updatable & Pausable) {
        updatableTargets.removeObject(updatable)
    }
    
    public func schedule(fixedUpdatable: FixedUpdatable & Pausable) {
        fixedUpdatableTargets.append(fixedUpdatable)
        fixedUpdatableTargetsNeedSorting = true
    }
    
    public func unschedule(fixedUpdatable: FixedUpdatable & Pausable) {
        fixedUpdatableTargets.removeObject(fixedUpdatable)
    }
}
