//
//  Timer.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public typealias TimerBlock = (Timer) -> Void

internal let TIMER_REPEAT_COUNT_FOREVER = Int.max

/** Contains information about a scheduled selector. Returned by [Node schedule:interval:] and related methods.
 
 @note New Timer objects can only be created with the schedule methods. Timer should not be subclassed.
 */
public final class Timer {
    /** @name Interval and Repeat Count */
    /** Number of times to run the selector again. First run does not count as a repeat. */
    var repeatCount = 0
    /** Amount of time to wait between selector calls. Defaults to the initial delay value.
     
     `Time` is a typedef for `Float`. */
    var repeatInterval: Time = 0.0
    /** @name Time Info */
    /** Elapsed time since the last invocation.
     
     `Time` is a typedef for `Float`. */
    internal(set) var deltaTime: Time = 0.0
    /** Absolute time the timer will invoke at.
     
     `Time` is a typedef for `Float`. */
    var invokeTime: Time {
        return paused || invalid ? Time.infinity : (invokeTimeInternal + pauseDelay)
    }
    
    // May differ from invoke time due to pausing.
    internal var invokeTimeInternal: Time = 0.0
    // purposefully undocumented: Scheduler is a private, undocumented class
    // Scheduler this timer was invoked from. Useful if you need to schedule more timers, or aess lastUpdate times, etc.
    let scheduler: Scheduler
    // purposefully undocumented
    /* Track an object along with the timer. [Node schedule:interval:] methods use this to store the selector name. */
    var userData: AnyObject!

    /** @name Pausing and Stopping Timer */
    /** Whether the timer is paused. */
    var paused = false {
        didSet {
            if paused != oldValue {
                let currentTime = scheduler.currentTime
                
                // This should ensure _pauseDelay is always positive since currentTime can never decrease.
                self.pauseDelay += max(invokeTimeInternal - currentTime, 0.0) * (paused ? 1.0 : -1.0)
                if paused && !scheduled {
                    self.apply(pauseDelay: currentTime)
                    scheduler.schedule(timer: self)
                }
            }
        }
    }
    /** Returns YES if the timer is no longer scheduled. */
    var invalid: Bool {
        return block == nil
    }
    
    internal var pauseDelay: Time = 0.0
    // Invocation requires an extra delay due to being paused.
    internal var requiresDelay: Bool {
        return pauseDelay > 0.0
    }
    
    // If the timer is currently added to the heap or not.
    internal var scheduled: Bool = false
    
    internal var block: TimerBlock?
    internal var scheduledTarget: ScheduledTarget?
    // Timers form a linked list per target.
    internal var next: Timer?
    
    init(delay: Time, scheduler: Scheduler, scheduledTarget: ScheduledTarget, block: TimerBlock?) {
        self.scheduler = scheduler
        self.scheduledTarget = scheduledTarget
        self.block = block
        self.deltaTime = delay
        self.invokeTimeInternal = scheduler.currentTime + delay
        self.repeatInterval = delay
    }

}

// MARK: Methods
extension Timer {
    /** Cancel the timer. */
    func invalidate() {
        block = nil
        scheduledTarget = nil
        repeatCount = 0
    }
    
    // purposefully undocumented: same as setting repeatCount and repeatInterval
    // Set the timer to repeat once with the given interval.
    // Can be used from a timer block to make the timer run again.
    func repeatOnce(interval: Time) {
        repeatCount = 1
        repeatInterval = interval
    }
    
    func apply(pauseDelay currentTime: Time) {
        invokeTimeInternal = max(invokeTimeInternal, currentTime) + pauseDelay
        pauseDelay = 0.0
    }
}

extension Timer: Comparable {
    @inline(__always)
    public static func ==(lhs: Timer, rhs: Timer) -> Bool {
        return lhs.invokeTimeInternal == rhs.invokeTimeInternal
    }

    @inline(__always)
    public static func <(lhs: Timer, rhs: Timer) -> Bool {
        return lhs.invokeTimeInternal < rhs.invokeTimeInternal
    }
    
    @inline(__always)
    public static func <=(lhs: Timer, rhs: Timer) -> Bool {
        return lhs.invokeTimeInternal <= rhs.invokeTimeInternal
    }
    
    @inline(__always)
    public static func >(lhs: Timer, rhs: Timer) -> Bool {
        return lhs.invokeTimeInternal > rhs.invokeTimeInternal
    }
    
    @inline(__always)
    public static func >=(lhs: Timer, rhs: Timer) -> Bool {
        return lhs.invokeTimeInternal >= rhs.invokeTimeInternal
    }
}
