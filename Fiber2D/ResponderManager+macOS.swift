//
//  ResponderManager+macOS.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 08.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

#if os(OSX)
    
import Cocoa

internal extension ResponderManager {
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
}
    
#endif
