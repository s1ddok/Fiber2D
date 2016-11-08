//
//  Responder.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 25.05.16.
//  Copyright © 2016 Fiber2D. All rights reserved.
//

import SwiftMath
import Cocoa

/**
 Responder is the base class for all nodes.
 It exposes the touch and mouse interface to any node, which enables user interaction.
 It is somewhat similar to [UIResponder](https://developer.apple.com/library/IOs/documentation/UIKit/Reference/UIResponder_Class/index.html).
 
 To make a responder react to user interaction, the touchesXXX / mouseXXX event must be overridden in your node subclass.
 If a class does not implement these selectors, the event will be passed on to the next node in the Fiber2D responder chain.
 To force the events to be passed to next responder, call the super implementation before returning from the event.
 
 ### Subclassing Notes
 You should not create subclasses of Responder. Instead subclass from Node if you need a plain basic node, or other node classes that best fit the purpose.
 */
open class Responder {
    /// -----------------------------------------------------------------------
    /// @name Enabling Input Events
    /// -----------------------------------------------------------------------
    /** Enables user interaction on a node. */
    var userInteractionEnabled = false {
        didSet {
            if userInteractionEnabled != userInteractionEnabled {
                Director.current.responderManager.markAsDirty()
            }
        }
    }
    /** Enables multiple touches inside a single node. */
    var multipleTouchEnabled: Bool = false
    /// -----------------------------------------------------------------------
    /// @name Customize Event Behavior
    /// -----------------------------------------------------------------------
    /**
     *  Continues to send touch events to the node that received the initial touchBegan, even when the touch has subsequently moved outside the node.
     *
     *  If set to NO, touches will be cancelled if they move outside the node's area.
     *  And if touches begin outside the node but subsequently move onto the node, the node will receive the touchBegan event.
     */
    var claimsUserInteraction: Bool = true

    /**
     *  All other touches will be cancelled / ignored if a node with exclusive touch is active.
     *  Only one exclusive touch node can be active at a time.
     */
    var exclusiveTouch: Bool = false
    /**
     *  Expands (or contracts) the hit area of the node.
     *  The expansion is calculated as a margin around the sprite, in points.
     */
    var hitAreaExpansion: Float = 0.0
    /**
     *  If this node clipInput, touch events outside the bounds of this node will not be sent to the children of this node.
     *  Only touches within this node's context rect will be sent to its children.
     */
    var clipsInput: Bool = false

    func hitTestWithWorldPos(_ pos: Point) -> Bool {
        return false
    }
    
    func clippedHitTestWithWorldPos(_ pos: Point) -> Bool {
        return false
    }
    
    open func inputBegan(_ input: Input) {
        Director.current.responderManager.discardCurrentEvent()
    }
    
    open func inputMoved(_ input: Input) {
        Director.current.responderManager.discardCurrentEvent()
    }
    
    open func inputDragged(_ input: Input) {
        Director.current.responderManager.discardCurrentEvent()
    }
    
    open func inputEnd(_ input: Input) {
        Director.current.responderManager.discardCurrentEvent()
    }
    
    open func inputCancelled(_ input: Input) {
        Director.current.responderManager.discardCurrentEvent()
    }
    
    #if os(OSX)
    func scrollWheel(_ theEvent: NSEvent) {
        Director.current.responderManager.discardCurrentEvent()
    }
    
    func keyDown(_ theEvent: NSEvent) {
        Director.current.responderManager.discardCurrentEvent()
    }
    
    func keyUp(_ theEvent: NSEvent) {
        Director.current.responderManager.discardCurrentEvent()
    }
    
    func flagsChanged(_ theEvent: NSEvent) {
        Director.current.responderManager.discardCurrentEvent()
    }
    #endif
}
