//
//  PhysicsWorld+Internal.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 18.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

internal extension Node {
    internal func beforeSimulation(parentToWorldTransform: Matrix4x4f, nodeParentScaleX: Float, nodeParentScaleY: Float, parentRotation: Angle) {
        let scaleX = nodeParentScaleX * self.scaleX
        let scaleY = nodeParentScaleY * self.scaleY
        let rotation = parentRotation + self.rotation
        
        let nodeToWorldTransform = parentToWorldTransform * self.nodeToParentMatrix
        
        //if let physicsBody =  {
            // physicsBody.beforeSimulation(
        //}
        
        for c in children {
            c.beforeSimulation(parentToWorldTransform: nodeToWorldTransform,
                               nodeParentScaleX: scaleX, nodeParentScaleY: scaleY,
                               parentRotation: rotation)
        }
    }
    
    internal func afterSimulation(parentToWorldTransform: Matrix4x4f, parentRotation: Angle) {
        let nodeToWorldTransform = parentToWorldTransform * self.nodeToParentMatrix
        let nodeRotation = parentRotation + self.rotation
        
        //if let physicsBody =  {
        // physicsBody.beforeSimulation(
        //}
        
        for c in children {
            c.afterSimulation(parentToWorldTransform: nodeToWorldTransform, parentRotation: nodeRotation)
        }
    }
}

func collisionBeginCallbackFunc(_ arb: UnsafeMutablePointer<cpArbiter>?, _ space: UnsafeMutablePointer<cpSpace>?, _ world: cpDataPointer?) -> cpBool {
    return cpBool.allZeros
}
func collisionPreSolveCallbackFunc(_ arb: UnsafeMutablePointer<cpArbiter>?, _ space: UnsafeMutablePointer<cpSpace>?, _ world: cpDataPointer?) -> cpBool {
    return cpBool.allZeros
}
func collisionPostSolveCallbackFunc(_ arb: UnsafeMutablePointer<cpArbiter>?, _ space: UnsafeMutablePointer<cpSpace>?, _ world: cpDataPointer?) -> Void {
}
func collisionSeparateCallbackFunc(_ arb: UnsafeMutablePointer<cpArbiter>?, _ space: UnsafeMutablePointer<cpSpace>?, _ world: cpDataPointer?) -> Void {
}

internal extension PhysicsWorld {


}
