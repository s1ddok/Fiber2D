//
//  ResponderManager.swift
//
//  Created by Andrey Volodin on 07.06.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath
import Cocoa

public enum MouseButton: Int {
    case left
    case right
    case other
}
/**
 *  Defines a running iOS/OSX responder.
 */
internal final class RunningResponder {
    /**
     *  Holdes the target of the touch. This is the node which accepted the touch.
     */
    var target: Node!
    #if os(iOS)
    /**
     *  Holds the current touch. Note that touches must not be retained.
     */
    weak var touch: CCTouch!
    /**
     *  Holdes the current event. Note that events must not be retained.
     */
    weak var event: CCTouchEvent!
    #endif
    
    #if os(OSX)
    /**
     *  Button in the currently ongoing event.
     */
    var button: MouseButton!
    #endif
}

let RESPONDER_MANAGER_BUFFER_SIZE = 128

/**
 *  The responder manager handles touches.
 */
internal final class ResponderManager : NSObject {
    /**
     *  Enables the responder manager.
     *  When the responder manager is disabled, all current touches will be cancelled and no further touch handling registered.
     */
    var enabled = true {
        didSet {
            guard oldValue != enabled else {
                return
            }
            // cancel ongoing touches, if disabled
            if !enabled {
                self.cancelAllResponders()
            }
        }
    }
    
    internal var responderList = [Node]() // list of active responders
    internal var dirty = true// list of responders should be rebuild
    internal var currentEventProcessed: Bool = false // current event was processed
    internal var exclusiveMode = false // manager only responds to current exclusive responder
    
    internal var director: Director!
    internal var runningResponderList = [RunningResponder]()
    
    init(director: Director) {
        super.init()
        self.director = director
        // reset touch handling
        self.removeAllResponders()
    }
    
    func discardCurrentEvent() {
        self.currentEventProcessed = false
    }
    
    func buildResponderList() {
        // rebuild responder list
        self.removeAllResponders()
        assert(director != nil, "Missing current director. Probably not bound.")
        assert(director.runningScene != nil, "Missing current running scene.")
        self.buildResponderList(director.runningScene!)
        self.dirty = false
    }
    
    func buildResponderList(_ node: Node) {
        // dont add invisible nodes
        if !node.visible {
            return
        }
        var shouldAddNode: Bool = node.userInteractionEnabled
        
        defer {
            // if eligible, add the current node to the responder list
            if shouldAddNode {
                self.addResponder(node)
            }
        }

        // scan through children, and build responder list
        for child: Node in node.children {
            if shouldAddNode && child.zOrder >= 0 {
                self.addResponder(node)
                shouldAddNode = false
            }
            self.buildResponderList(child)
        }
    }
    
    func addResponder(_ responder: Node!) {
        guard responder != nil else {
            assertionFailure("Trying to add a nil responder")
            return
        }
        
        self.responderList.append(responder)
        assert(responderList.count < RESPONDER_MANAGER_BUFFER_SIZE,
               "Number of touchable nodes pr. scene can not exceed \(RESPONDER_MANAGER_BUFFER_SIZE)")
    }
    
    func removeAllResponders() {
        responderList = []
    }
    
    func cancelAllResponders() {
        runningResponderList.forEach { (r: RunningResponder) in
            self.cancelResponder(r)
        }
        runningResponderList = []
        self.exclusiveMode = false
    }
    
    func markAsDirty() {
        self.dirty = true
    }

    func nodeAtPoint(_ pos: Point) -> Node? {
        if dirty {
            self.buildResponderList()
        }
        
        // scan backwards through touch responders
        for node in responderList.reversed() {
            // check for hit test
            if node.hitTestWithWorldPos(pos) {
                return (node)
            }
        }
        // nothing found
        return nil
    }
    
    func nodesAtPoint(_ pos: Point) -> [AnyObject] {
        if dirty {
            self.buildResponderList()
        }
        
        return responderList.filter {
            $0.hitTestWithWorldPos(pos)
        }
    }
    
    #if os(iOS)
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
    #endif
    
    #if os(OSX)
    func mouseDown(_ theEvent: NSEvent, button: MouseButton) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        self.executeOnEachResponder({(node: Node) -> Void in
            node.mouseDown(theEvent, button: button)
            if self.currentEventProcessed {
                self.addResponder(node, withButton: button)
            }
            }, withEvent: theEvent)
    }
    
    func mouseDragged(_ theEvent: NSEvent, button: MouseButton) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        
        if let responder: RunningResponder = self.responderForButton(button) {
            // This drag event is already associated with a specific target.
            // Items that claim user interaction receive events even if they occur outside of the bounds of the object.
            if responder.target.claimsUserInteraction || responder.target.clippedHitTestWithWorldPos(director.convertEventToGL(theEvent)) {
                Director.pushCurrentDirector(director)
                responder.target.mouseDragged(theEvent, button: button)
                Director.popCurrentDirector()
            }
            else {
                runningResponderList.removeObject(responder)
            }
        }
        else {
            self.executeOnEachResponder({(node: Node) -> Void in
                node.mouseDragged(theEvent, button: button)
                if self.currentEventProcessed {
                    self.addResponder(node, withButton: button)
                }
                }, withEvent: theEvent)
        }
    }
    
    func mouseUp(_ theEvent: NSEvent, button: MouseButton) {
        if dirty {
            self.buildResponderList()
        }
        
        if let responder = self.responderForButton(button) {
            Director.pushCurrentDirector(director)
            responder.target.mouseUp(theEvent, button: button)
            Director.popCurrentDirector()
            runningResponderList.removeObject(responder)
        }
    }
    
    func scrollWheel(_ theEvent: NSEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        // if otherMouse is active, scrollWheel goes to that node
        // otherwise, scrollWheel goes to the node under the cursor
        
        if let responder: RunningResponder = self.responderForButton(.other) {
            self.currentEventProcessed = true
            Director.pushCurrentDirector(director)
            responder.target.scrollWheel(theEvent)
            Director.popCurrentDirector()
            // if mouse was accepted, return
            if currentEventProcessed {
                return
            }
        }
        self.executeOnEachResponder({(node: Node) -> Void in
            node.scrollWheel(theEvent)
            }, withEvent: theEvent)
    }
    
    func mouseMoved(_ theEvent: NSEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        self.executeOnEachResponder({(node: Node) -> Void in
            node.mouseMoved(theEvent)
            }, withEvent: theEvent)
    }
    
    func executeOnEachResponder(_ block: (Node) -> Void, withEvent theEvent: NSEvent) {
        Director.pushCurrentDirector(director)
        // scan through responders, and find first one
        for node in responderList.reversed() {
            // check for hit test
            if node.clippedHitTestWithWorldPos(director.convertEventToGL(theEvent)) {
                self.currentEventProcessed = true
                block(node)
                // if mouse was accepted, break
                if currentEventProcessed {
                    
                }
            }
        }
        Director.popCurrentDirector()
    }
    
    func keyDown(_ theEvent: NSEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        Director.pushCurrentDirector(director)
        responderList.reversed().forEach {
            $0.keyDown(theEvent)
        }
        Director.popCurrentDirector()
    }
    
    func keyUp(_ theEvent: NSEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        Director.pushCurrentDirector(director)
        responderList.reversed().forEach {
            $0.keyUp(theEvent)
        }
        Director.popCurrentDirector()
    }
    
    func flagsChanged(_ theEvent: NSEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        Director.pushCurrentDirector(director)
        responderList.reversed().forEach {
            $0.flagsChanged(theEvent)
        }
        Director.popCurrentDirector()
    }
    // finds a responder object for an event
    
    func responderForButton(_ button: MouseButton) -> RunningResponder? {
        for touchEntry: RunningResponder in runningResponderList {
            if touchEntry.button == button {
                return touchEntry
            }
        }
        return nil
    }
    // adds a responder object ( running responder ) to the responder object list
    
    func addResponder(_ node: Node, withButton button: MouseButton) {
        var touchEntry: RunningResponder
        // create a new touch object
        touchEntry = RunningResponder()
        touchEntry.target = node
        touchEntry.button = button
        runningResponderList.append(touchEntry)
    }
    
    func cancelResponder(_ responder: RunningResponder) {
        runningResponderList.removeObject(responder)
    }
    
    #endif
}
