//
//  ResponderManager+iOS.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 08.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
import SwiftMath

public extension ResponderManager {
    
    public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard enabled && !exclusiveMode else {
            return
        }
        
        // End editing any text fields
        (director.view as? UIView)?.endEditing(true)
        if dirty {
            self.buildResponderList()
        }
        
        // go through all touches
        for touch in touches {
            let input = director.convertUITouchToInput(touch)
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
                    self.add(responder: responder, withTouch: touch, andEvent: event)
                    break
                }
            }
        }
    }
    
    public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard enabled else {
            return
        }
        
        if dirty {
            self.buildResponderList()
        }
        
        // go through all touches
        for touch in touches {
            let input = director.convertUITouchToInput(touch)
            let worldPosition = input.screenPosition
            
            // get touch object
            // if a touch object was found
            if let touchEntry = self.responder(for: touch) {
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
                            self.add(responder: responder, withTouch: touch, andEvent: event)
                            break
                        }
                    }
                }
            }
        }
    }
    
    public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard enabled else {
            return
        }
        
        if dirty {
            self.buildResponderList()
        }
        
        // go through all touches
        for touch in touches {
            // get touch object
            if let touchEntry = self.responder(for: touch) {
                // end the touch
                touchEntry.target.inputEnd(director.convertUITouchToInput(touch))
                // remove from list
                runningResponderList.removeObject(touchEntry)
                // always end exclusive mode
                self.exclusiveMode = false
            }
        }
    }
    
    public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard enabled else {
            return
        }
        
        if dirty {
            self.buildResponderList()
        }
        
        // go through all touches
        for touch in touches {
            // get touch object
            if let touchEntry = self.responder(for: touch) {
                self.cancel(responder: touchEntry)
                // always end exclusive mode
                self.exclusiveMode = false
            }
        }
    }
    
    // adds a responder object (running responder) to the responder object list
    internal func add(responder: Responder, withTouch touch: UITouch, andEvent event: UIEvent?) {
        // create a new touch object
        let touchEntry = RunningResponder(target: responder)
        touchEntry.touch = touch
        touchEntry.event = event
        runningResponderList.append(touchEntry)
    }
    
    // finds a responder object for a touch
    internal func responder(for touch: UITouch) -> RunningResponder? {
        return runningResponderList.first { $0.touch == touch }
    }
    
    // cancels a running responder
    internal func cancel(responder: RunningResponder) {
        responder.target.inputCancelled(director.convertUITouchToInput(responder.touch))
        // remove from list
        runningResponderList.removeObject(responder)
    }
    
}
    
#endif
