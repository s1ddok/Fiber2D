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
 Responder is the base class for all components that handle user input.
 It exposes the touch and mouse interface to any node.
 It is somewhat similar to [UIResponder](https://developer.apple.com/library/IOs/documentation/UIKit/Reference/UIResponder_Class/index.html).
 
 To make a responder react to user interaction, the touchesXXX / mouseXXX event must be overridden in your node subclass.
 To force the events to be passed to next responder, call the super implementation before returning from the event.
 */
open class Responder {

    /// @name Enabling Input Events

    /** Enables user interaction on a node. */
    // TODO: Should implement Behaviour protocol instead
    public var userInteractionEnabled = true {
        didSet {
            if userInteractionEnabled != userInteractionEnabled {
                Director.current.responderManager.markAsDirty()
            }
        }
    }
    
    #if os(iOS) || os(tvOS) || os(Android)
    /** Enables multiple touches inside a single node. */
    public var multipleTouchEnabled: Bool = false
    
    /**
     *  All other touches will be cancelled / ignored if a node with exclusive touch is active.
     *  Only one exclusive touch node can be active at a time.
     */
    public var exclusiveTouch: Bool = false
    #endif
    
    /// @name Customize Event Behavior

    /**
     *  Continues to send touch events to the node that received the initial touchBegan, even when the touch has subsequently moved outside the node.
     *
     *  If set to NO, touches will be cancelled if they move outside the node's area.
     *  And if touches begin outside the node but subsequently move onto the node, the node will receive the touchBegan event.
     */
    public var claimsUserInteraction: Bool = true

    /**
     *  Expands (or contracts) the hit area of the node.
     *  The expansion is calculated as a margin around the sprite, in points.
     */
    public var hitAreaExpansion: Float = 0.0
    
    /**
     * Current owner of this component
     */
    internal(set) public weak var owner: Node?

    /** Returns YES, if touch is inside sprite
     Added hit area expansion / contraction
     Override for alternative clipping behavior, such as if you want to clip input to a circle.
     */
    open func hitTest(worldPosition pos: Point) -> Bool {
        guard let owner = self.owner else {
            print("Can't hit-test orphan component")
            return false
        }
        
        let p = owner.convertToNodeSpace(pos)
        let h = -hitAreaExpansion
        let offset = Point(-h, -h)
        // optimization
        let contentSizeInPoints = owner.contentSizeInPoints
        let size: Size = Size(width: contentSizeInPoints.width - offset.x, height: contentSizeInPoints.height - offset.y)
        return !(p.y < offset.y || p.y > size.height || p.x < offset.x || p.x > size.width)
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
    
    open func keyDown(_ key: Key) {
        Director.current.responderManager.discardCurrentEvent()
    }
    
    open func keyUp(_ key: Key) {
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
