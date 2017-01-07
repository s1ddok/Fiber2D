//
//  ActionContinous+Default.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 05.01.17.
//
//

/**
 * Internal action model that does nothing
 */
internal struct ActionEmpty: ActionModel {}

/**
 This action waits for the time specified. Used in sequences to delay (pause) the sequence for a given time.
 
 Example, wait for 2 seconds:
 
 let delay = ActionWait(for: 2.0)
 */
public func ActionWait(for time: Time) -> ActionContinousContainer {
    return ActionEmpty().continously(duration: time)
}
