//
//  ResponderManager+Mouse.swift
//  Fiber2D-iOS
//
//  Created by Andrey Volodin on 08.01.17.
//
//

#if os(macOS) || os(Linux)
import SwiftMath

public extension ResponderManager {
    
    internal func executeOnEachResponder(_ block: (Responder) -> Void, screenPosition: Point) {
        Director.pushCurrentDirector(director)
        // scan through responders, and find first one
        for responder in responderList.lazy.reversed() {
            // check for hit test
            if responder.hitTest(worldPosition: screenPosition) {
                self.currentEventProcessed = true
                block(responder)
                // if mouse was accepted, break
                break
            }
        }
        Director.popCurrentDirector()
    }
    
    internal func cancel(responder: RunningResponder) {
        runningResponderList.removeObject(responder)
    }
    
    // finds a responder object for an event
    internal func responder(for button: MouseButton) -> RunningResponder? {
        for touchEntry in runningResponderList {
            if touchEntry.button == button {
                return touchEntry
            }
        }
        return nil
    }
    
    // adds a responder object ( running responder ) to the responder object list
    internal func add(responder: Responder, withButton button: MouseButton) {
        // create a new input object
        let touchEntry = RunningResponder(target: responder)
        touchEntry.button = button
        runningResponderList.append(touchEntry)
    }
    
}
#endif
