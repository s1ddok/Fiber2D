//
//  ResponderManager+macOS.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 08.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

#if os(OSX)
    
import Cocoa
import SwiftMath

public extension ResponderManager {
    public func mouseDown(_ theEvent: NSEvent, button: MouseButton) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        
        let mouseLocation = director.convertEventToGL(theEvent)
        let input = Input(screenPosition: mouseLocation, mouseButton: button)
        
        self.executeOnEachResponder({ node in
            node.inputBegan(input)
            if self.currentEventProcessed {
                self.add(responder: node, withButton: button)
            }
        }, screenPosition: mouseLocation)
    }
    
    public func mouseDragged(_ theEvent: NSEvent, button: MouseButton) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        
        let mouseLocation = director.convertEventToGL(theEvent)
        let input = Input(screenPosition: mouseLocation, mouseButton: button)
        
        if let responder = self.responder(for: button) {
            // This drag event is already associated with a specific target.
            // Items that claim user interaction receive events even if they occur outside of the bounds of the object.
            if responder.target.claimsUserInteraction || responder.target.hitTest(worldPosition: mouseLocation) {
                Director.pushCurrentDirector(director)
                responder.target.inputDragged(input)
                Director.popCurrentDirector()
            } else {
                runningResponderList.removeObject(responder)
            }
        } else {
            self.executeOnEachResponder({ node in
                node.inputDragged(input)
                if self.currentEventProcessed {
                    self.add(responder: node, withButton: button)
                }
            }, screenPosition: mouseLocation)
        }
    }
    
    public func mouseUp(_ theEvent: NSEvent, button: MouseButton) {
        if dirty {
            self.buildResponderList()
        }
        
        let mouseLocation = director.convertEventToGL(theEvent)
        let input = Input(screenPosition: mouseLocation, mouseButton: button)
        
        if let responder = self.responder(for: button) {
            Director.pushCurrentDirector(director)
            responder.target.inputEnd(input)
            Director.popCurrentDirector()
            runningResponderList.removeObject(responder)
        }
    }
    
    public func mouseMoved(_ theEvent: NSEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        
        let mouseLocation = director.convertEventToGL(theEvent)
        let input = Input(screenPosition: mouseLocation, mouseButton: .none)
        
        self.executeOnEachResponder({ node in
            node.inputMoved(input)
        }, screenPosition: mouseLocation)
    }
    
    public func executeOnEachResponder(_ block: (Responder) -> Void, screenPosition: Point) {
        Director.pushCurrentDirector(director)
        // scan through responders, and find first one
        for responder in responderList.reversed().lazy {
            // check for hit test
            if responder.hitTest(worldPosition: screenPosition) {
                self.currentEventProcessed = true
                block(responder)
                // if mouse was accepted, break
                if currentEventProcessed {
                    break
                }
            }
        }
        Director.popCurrentDirector()
    }
    
    public func scrollWheel(_ theEvent: NSEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        
        let mouseLocation = director.convertEventToGL(theEvent)
        
        // if otherMouse is active, scrollWheel goes to that node
        // otherwise, scrollWheel goes to the node under the cursor
        if let responder = self.responder(for: .other) {
            self.currentEventProcessed = true
            Director.pushCurrentDirector(director)
            responder.target.scrollWheel(theEvent)
            Director.popCurrentDirector()
            // if mouse was accepted, return
            if currentEventProcessed {
                return
            }
        }
        
        self.executeOnEachResponder({ node in
            node.scrollWheel(theEvent)
        }, screenPosition: mouseLocation)
    }
    
    public func keyDown(_ theEvent: NSEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        Director.pushCurrentDirector(director)
        responderList.reversed().lazy.forEach {
            $0.keyDown(theEvent)
        }
        Director.popCurrentDirector()
    }
    
    public func keyUp(_ theEvent: NSEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        Director.pushCurrentDirector(director)
        responderList.reversed().lazy.forEach {
            $0.keyUp(theEvent)
        }
        Director.popCurrentDirector()
    }
    
    public func flagsChanged(_ theEvent: NSEvent) {
        if !enabled {
            return
        }
        if dirty {
            self.buildResponderList()
        }
        Director.pushCurrentDirector(director)
        responderList.reversed().lazy.forEach {
            $0.flagsChanged(theEvent)
        }
        Director.popCurrentDirector()
    }
    
    internal func cancel(responder: RunningResponder) {
        runningResponderList.removeObject(responder)
    }
    
    // finds a responder object for an event
    fileprivate func responder(for button: MouseButton) -> RunningResponder? {
        for touchEntry in runningResponderList {
            if touchEntry.button == button {
                return touchEntry
            }
        }
        return nil
    }
    
    // adds a responder object ( running responder ) to the responder object list
    fileprivate func add(responder: Responder, withButton button: MouseButton) {
        // create a new input object
        let touchEntry = RunningResponder(target: responder)
        touchEntry.button = button
        runningResponderList.append(touchEntry)
    }
}
    
#endif
