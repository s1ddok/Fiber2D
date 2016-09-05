//
//  ActionInstant+Node.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 05.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/**
 This action executes a code block. The block takes no parameters and returns nothing.
 
 @note This is meant to be instant action. If you will create this a continous one, the block will be called every frame.
 
 ### Passing Parameters
 
 Blocks can access all variables in scope, both variables local to the method as well as instance variables.

 Running a block is often preferable then using Target-Action pattern.
 
 ### Memory Management
 
 To avoid potential memory management issues it is recommended to use a weak self reference inside
 the block. If you are knowledgeable about [memory management with ARC and blocks](http://stackoverflow.com/questions/20030873/always-pass-weak-reference-of-self-into-block-in-arc)
 you can omit the weakSelf reference at your discretion. Otherwise use [unowned self] attribute in block
 
 ### Code Example
 
 Example block that reads and modifies a variable in scope and rotates a node to illustrate the code syntax:
 
 let callBlock = ActionCallBlock {[unowned self] () -> () in
  self.rotation += 90;
 }.instantly
 
 [self runAction:callBlock];
 
 @see [Blocks Programming Guide](https://developer.apple.com/library/ios/documentation/cocoa/Conceptual/Blocks/Articles/00_Introduction.html)
 */

public struct ActionCallBlock: ActionModel {
    public let block: () -> ()
    
    /**
     *  Creates the action with the specified block, to be used as a callback.
     *
     *  @param block Block to run. Block takes no parameters, returns nothing.
     *
     *  @return The call block action.
     */
    init(block: @escaping () -> ()) {
        self.block = block
    }
    
    public func update(state: Float) {
        block()
    }
}

/**
 This action will hide the target by setting its `visible` property to NO.
 
 The action is created using the default Action initializer, don't use target one.
 */
public struct ActionHide: ActionModel {
    public var target: Node!
    
    public init() { }
    public mutating func start(with target: AnyObject?) {
        self.target = target as! Node
    }
    public mutating func update(state: Float) {
        target.visible = false
    }
}

/**
 This action will make the target visible by setting its `visible` property to YES.
 
 The action is created using the default Action initializer, don't use target one.
 */
public struct ActionShow: ActionModel {
    public var target: Node!
    
    public init() { }
    public mutating func start(with target: AnyObject?) {
        self.target = target as! Node
    }
    public mutating func update(state: Float) {
        target.visible = true
    }
}

/**
 This action toggles the target's visibility by altering the `visible` property.
 
 The action is created using the default Action initializer, don't use target one.
 */
public struct ActionToggleVisibility: ActionModel {
    public var target: Node!
    
    public init() { }
    public mutating func start(with target: AnyObject?) {
        self.target = target as! Node
    }
    public mutating func update(state: Float) {
        target.visible = !target.visible
    }
}

/** This action will remove the node running this action from its parent.
 
 The action is created using the default Action initializer, don't use target one.
 */
public struct ActionRemove: ActionModel {
    public var target: Node!
    
    public init() { }
    public mutating func start(with target: AnyObject?) {
        self.target = target as! Node
    }
    public mutating func update(state: Float) {
        target.removeFromParent()
    }
}

