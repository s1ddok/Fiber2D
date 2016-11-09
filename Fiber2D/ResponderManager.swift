//
//  ResponderManager.swift
//
//  Created by Andrey Volodin on 07.06.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath
import Cocoa

// TODO: Current implementation doesn't handle the case when responder is being removed during move events
// I bet it sits in runningResponders forever

/**
 *  Defines a running iOS/OSX responder.
 */
internal final class RunningResponder {
    /**
     *  Holdes the target of the touch. This is the node which accepted the touch.
     */
    unowned var target: Responder
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
    
    public init(target: Responder) {
        self.target = target
    }
}

/**
 *  The responder manager handles touches and mouse.
 */
internal final class ResponderManager {
    
    /**
     *  Enables the responder manager.
     *  When the responder manager is disabled, all current touches will be cancelled and no further touch handling registered.
     */
    public var enabled = true {
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
    
    internal var responderList = [Responder]() // list of active responders
    internal var dirty = true// list of responders should be rebuild
    internal var currentEventProcessed: Bool = false // current event was processed
    internal var exclusiveMode = false // manager only responds to current exclusive responder
    
    internal let director: Director
    internal var runningResponderList = [RunningResponder]()
    
    init(director: Director) {
        self.director = director
        // reset touch handling
        self.removeAllResponders()
    }
    
    /**
     *  Discards current event.
     *  Do not call directly, call super.touchesXXX() or super.mouseXXX() in stead.
     */
    func discardCurrentEvent() {
        self.currentEventProcessed = false
    }
    
    func buildResponderList() {
        // rebuild responder list
        self.removeAllResponders()
        
        guard let scene = director.runningScene else {
            fatalError("Missing current running scene.")
        }
        
        self.buildResponderList(scene)
        self.dirty = false
    }
    
    func buildResponderList(_ node: Node) {
        // dont add invisible nodes
        if !node.visible {
            return
        }
        
        var shouldAddNode = node.responder != nil && node.responder!.userInteractionEnabled
        
        defer {
            // if eligible, add the current node to the responder list
            if shouldAddNode {
                self.add(responder: node.responder!)
            }
        }

        // scan through children, and build responder list
        for child: Node in node.children {
            if shouldAddNode && child.zOrder >= 0 {
                self.add(responder: node.responder!)
                shouldAddNode = false
            }
            self.buildResponderList(child)
        }
    }
    
    /**
     *  Adds a responder to the responder manager.
     *  Normally there is no need to call this method directly.
     *
     *  @param responder A Node object.
     */
    internal func add(responder: Responder) {
        responderList.append(responder)
    }
    
    /**
     *  Removes all responders.
     *  Normally there is no need to call this method directly.
     */
    public func removeAllResponders() {
        responderList = []
    }
    
    internal func cancelAllResponders() {
        runningResponderList.forEach { self.cancel(responder: $0) }
        runningResponderList = []
        self.exclusiveMode = false
    }
    
    /**
     *  Mark the responder chain as dirty, if responders state changes.
     *  Normally there is no need to call this method directly.
     */
    public func markAsDirty() {
        self.dirty = true
    }

    /**
     *  Returns the first responder at a certain world position.
     *
     *  @param pos World position ( this in most cases maps to the screen coordinates in points ).
     *
     *  @return The Node at the position (if any).
     */
    public func node(at pos: Point) -> Node? {
        if dirty {
            self.buildResponderList()
        }
        
        // scan backwards through touch responders
        for responder in responderList.reversed().lazy {
            // check for hit test
            if responder.hitTest(worldPosition: pos) {
                return responder.owner!
            }
        }
        // nothing found
        return nil
    }
    
    /**
     *  Returns a list of all responders at a certain world position.
     *
     *  @param pos World position ( this in most cases maps to the screen coordinates in points ).
     *
     *  @return Returns an array of Nodes at the given point. The top most responder will be the first entry.
     */
    public func nodes(at pos: Point) -> [Node] {
        if dirty {
            self.buildResponderList()
        }
        
        return responderList.filter {
            $0.hitTest(worldPosition: pos)
        }.map { $0.owner! }
    }
}
