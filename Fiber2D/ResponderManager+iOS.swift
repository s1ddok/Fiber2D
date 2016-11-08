//
//  ResponderManager+iOS.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 08.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

#if os(iOS)
import UIKit

internal extension ResponderManager {
    
    func touchesBegan(touches: Set<AnyObject>, withEvent event: CCTouchEvent) {
        if !enabled {
            return
        }
        if exclusiveMode {
            return
        }
        // End editing any text fields
        director.view!.endEditing(true)
        var responderCanAcceptTouch: Bool
        if dirty {
            self.buildResponderList()
        }
        // go through all touches
        for touch: CCTouch in touches {
            var worldTouchLocation: Point = director.convertToGL(touch.locationInView((director.view as! CCView)))
            // scan backwards through touch responders
            for var index = responderListCount - 1; index >= 0; index-- {
                var node: Node = responderList[index]
                // check for hit test
                if node.clippedHitTestWithWorldPos(worldTouchLocation) {
                    // check if node has exclusive touch
                    if node.isExclusiveTouch {
                        self.cancelAllResponders()
                        self.exclusiveMode = true
                    }
                    // if not a multi touch node, check if node already is being touched
                    responderCanAcceptTouch = true
                    if !node.isMultipleTouchEnabled {
                        // scan current touch objects, and break if object already has a touch
                        for responderEntry: RunningResponder in runningResponderList {
                            if responderEntry.target == node {
                                responderCanAcceptTouch = false
                            }
                        }
                    }
                    if !responderCanAcceptTouch {
                        
                    }
                    // begin the touch
                    self.currentEventProcessed = true
                    if node.respondsToSelector("touchBegan:withEvent:") {
                        node.touchBegan(touch, withEvent: event)
                    }
                    // if touch was processed, add it and break
                    if currentEventProcessed {
                        self.addResponder(node, withTouch: touch, andEvent: event)
                    }
                }
            }
        }
    }
    
    func touchesMoved(touches: Set<AnyObject>, withEvent event: CCTouchEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        // go through all touches
        for touch: CCTouch in touches {
            // get touch object
            var touchEntry: RunningResponder = self.responderForTouch(touch)
            // if a touch object was found
            if touchEntry != nil {
                var node: Node = (touchEntry.target as! Node)
                // check if it locks touches
                if node.claimsUserInteraction {
                    // move the touch
                    if node.respondsToSelector("touchMoved:withEvent:") {
                        node.touchMoved(touch, withEvent: event)
                    }
                }
                else {
                    // as node does not lock touch, check if it was moved outside
                    if !node.clippedHitTestWithWorldPos(director.convertToGL(touch.locationInView(director.view!))) {
                        // cancel the touch
                        if node.respondsToSelector("touchCancelled:withEvent:") {
                            node.touchCancelled(touch, withEvent: event)
                        }
                        // remove from list
                        runningResponderList.removeObject(touchEntry)
                        // always end exclusive mode
                        self.exclusiveMode = false
                    }
                    else {
                        // move the touch
                        if node.respondsToSelector("touchMoved:withEvent:") {
                            node.touchMoved(touch, withEvent: event)
                        }
                    }
                }
            }
            else {
                if !exclusiveMode {
                    // scan backwards through touch responders
                    for var index = responderListCount - 1; index >= 0; index-- {
                        var node: Node = responderList[index]
                        // if the touch responder does not lock touch, it will receive a touchBegan if a touch is moved inside
                        if !node.claimsUserInteraction && node.clippedHitTestWithWorldPos(director.convertToGL(touch.locationInView(director.view!))) {
                            // check if node has exclusive touch
                            if node.isExclusiveTouch {
                                self.cancelAllResponders()
                                self.exclusiveMode = true
                            }
                            // begin the touch
                            self.currentEventProcessed = true
                            if node.respondsToSelector("touchBegan:withEvent:") {
                                node.touchBegan(touch, withEvent: event)
                            }
                            // if touch was accepted, add it and break
                            if currentEventProcessed {
                                self.addResponder(node, withTouch: touch, andEvent: event)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func touchesEnded(touches: Set<AnyObject>, withEvent event: CCTouchEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        // go through all touches
        for touch: CCTouch in touches {
            // get touch object
            var touchEntry: RunningResponder = self.responderForTouch(touch)
            if touchEntry != nil {
                var node: Node = (touchEntry.target as! Node)
                // end the touch
                if node.respondsToSelector("touchEnded:withEvent:") {
                    node.touchEnded(touch, withEvent: event)
                }
                // remove from list
                runningResponderList.removeObject(touchEntry)
                // always end exclusive mode
                self.exclusiveMode = false
            }
        }
    }
    
    func touchesCancelled(touches: Set<AnyObject>, withEvent event: CCTouchEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        // go through all touches
        for touch: CCTouch in touches {
            // get touch object
            var touchEntry: RunningResponder = self.responderForTouch(touch)
            if touchEntry != nil {
                self.cancelResponder(touchEntry)
                // always end exclusive mode
                self.exclusiveMode = false
            }
        }
    }
    // finds a responder object for a touch
    
    func responderForTouch(touch: CCTouch) -> RunningResponder {
        for touchEntry: RunningResponder in runningResponderList {
            if touchEntry.touch == touch {
                return touchEntry
            }
        }
        return (nil)
    }
    // adds a responder object ( running responder ) to the responder object list
    
    func addResponder(node: Node, withTouch touch: CCTouch, andEvent event: CCTouchEvent) {
        var touchEntry: RunningResponder
        // create a new touch object
        touchEntry = RunningResponder()
        touchEntry.target = node
        touchEntry.touch = touch
        touchEntry.event = event
        runningResponderList.append(touchEntry)
    }
    // cancels a running responder
    
    func cancelResponder(responder: RunningResponder) {
        var node: Node = (responder.target as! Node)
        // cancel the touch
        if node.respondsToSelector("touchCancelled:withEvent:") {
            node.touchCancelled(responder.touch, withEvent: responder.event)
        }
        // remove from list
        runningResponderList.removeObject(responder)
    }
    
}
    
#endif
