//
//  ResponderManager+SDL.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 16.12.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

#if os(Android)
import CSDL2
import SwiftMath

public extension ResponderManager {
    
    public func fingerDown(event: SDL_TouchFingerEvent) {
        guard enabled && !exclusiveMode else {
            return
        }
        
        if dirty {
            self.buildResponderList()
        }
    
        let input = director.convertSDLTouchEventToInput(event)
        let worldTouchLocation = input.screenPosition
        // scan backwards through touch responders
        outer: for responder in responderList.lazy.reversed() {
            // check for hit test
            if responder.hitTest(worldPosition: worldTouchLocation) {
                // check if node has exclusive touch
                if responder.isExclusiveTouch {
                    self.cancelAllResponders()
                    self.exclusiveMode = true
                }
                
                // if not a multi touch node, check if node already is being touched
                if !responder.isMultipleTouchEnabled {
                    // scan current touch objects, and break if object already has a touch
                    for responderEntry in runningResponderList {
                        if responderEntry.target === responder {
                            break outer
                        }
                    }
                }
                
                // begin the touch
                self.currentEventProcessed = true
                responder.inputBegan(input)
                // if touch was processed, add it and break
                self.add(responder: responder, withEvent: event)
                break
            }
        }
    }
    
    public func fingerMoved(event: SDL_TouchFingerEvent) {
        guard enabled else {
            return
        }
        
        if dirty {
            self.buildResponderList()
        }
        
        let input = director.convertSDLTouchEventToInput(event)
        let worldPosition = input.screenPosition
        
        // get touch object
        // if a touch object was found
        if let touchEntry = self.responder(for: event.touchId) {
            let responder = touchEntry.target
            // check if it locks touches
            if responder.claimsUserInteraction {
                // move the touch
                responder.inputDragged(input)
            } else {
                // as node does not lock touch, check if it was moved outside
                if !responder.hitTest(worldPosition: worldPosition) {
                    // cancel the touch
                    responder.inputCancelled(input)
                    // remove from list
                    runningResponderList.removeObject(touchEntry)
                    // always end exclusive mode
                    self.exclusiveMode = false
                } else {
                    // move the touch
                    responder.inputDragged(input)
                }
            }
        } else if !exclusiveMode {
            // scan backwards through touch responders
            for responder in responderList.lazy.reversed() {
                // if the touch responder does not lock touch, it will receive a touchBegan if a touch is moved inside
                if !responder.claimsUserInteraction && responder.hitTest(worldPosition: worldPosition) {
                    // check if node has exclusive touch
                    if responder.isExclusiveTouch {
                        self.cancelAllResponders()
                        self.exclusiveMode = true
                    }
                    
                    // begin the touch
                    self.currentEventProcessed = true
                    responder.inputBegan(input)
                    
                    // if touch was accepted, add it and break
                    if currentEventProcessed {
                        self.add(responder: responder, withEvent: event)
                        break
                    }
                }
            }
        }
        
    }
    
    public func fingerUp(event: SDL_TouchFingerEvent) {
        guard enabled else {
            return
        }
        
        if dirty {
            self.buildResponderList()
        }
        
        // get touch object
        if let touchEntry = self.responder(for: event.touchId) {
            // end the touch
            touchEntry.target.inputEnd(director.convertSDLTouchEventToInput(event))
            // remove from list
            runningResponderList.removeObject(touchEntry)
            // always end exclusive mode
            self.exclusiveMode = false
        }
        
    }
    
    // adds a responder object (running responder) to the responder object list
    internal func add(responder: Responder, withEvent event: SDL_TouchFingerEvent) {
        // create a new touch object
        let touchEntry = RunningResponder(target: responder)
        touchEntry.touchID = event.touchId
        runningResponderList.append(touchEntry)
    }
    
    // finds a responder object for a touch
    internal func responder(for touchID: SDL_TouchID) -> RunningResponder? {
        return runningResponderList.first { $0.touchID == touchID }
    }
    
    // cancels a running responder
    internal func cancel(responder: RunningResponder) {
        // remove from list
        runningResponderList.removeObject(responder)
    }
    
}

#endif
