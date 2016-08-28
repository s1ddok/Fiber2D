//
//  Scheduler.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

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
    var timeScale: Time = 0.0
    /**
     Current time the scheduler is calling a block for.
     */
    private(set) var currentTime: Time = 0.0
    /**
     Time of the most recent update: calls.
     */
    private(set) var lastUpdateTime: Time = 0.0
    /**
     Time of the most recent fixedUpdate: calls.
     */
    private(set) var lastFixedUpdateTime: Time = 0.0
    /**
     Maximum allowed time step.
     If the CPU can't keep up with the game, time will slow down.
     */
    var maxTimeStep: Time = 0.0
    /**
     The time between fixedUpdate: calls.
     */
    var fixedUpdateInterval: Time = 0.0
}

extension Scheduler {
    internal func schedule(timer: Timer) {
    
    }
}
