//
//  Node+Transform.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation
import CoreGraphics

extension GLKVector2 {
    var isZero: Bool {
        return x == 0.0 && y == 0.0
    }
    
    init(point: CGPoint) {
        v.0 = Float(point.x)
        v.1 = Float(point.y)
    }
}
extension Node {
    /** Returns the matrix that transform the node's (local) space coordinates into the parent's space coordinates.
     The matrix is in points.
     @see [GLKMatrix4](https://developer.apple.com/library/ios/documentation/GLkit/Reference/GLKMatrix4/index.html)
     @see parentToNodeMatrix
     */
    func nodeToParentMatrix() -> GLKMatrix4 {
        if isTransformDirty {
            // Get content size
            // Convert position to points
            var positionInPoints: CGPoint
            if CCPositionTypeIsBasicPoints(positionType) {
                // Optimization for basic points (most common case)
                positionInPoints = position
            } else {
                positionInPoints = self.convertPositionToPoints(position, type: positionType)
            }
            
            let anchorPointInPoints = GLKVector2(point: self.anchorPointInPoints)
            // Get x and y
            var x = Float(positionInPoints.x)
            var y = Float(positionInPoints.y)
            // Rotation values
            // Change rotation code to handle X and Y
            // If we skew with the exact same value for both x and y then we're simply just rotating
            var cx: Float = 1
            var sx: Float = 0
            var cy: Float = 1
            var sy: Float = 0
            if rotationalSkewX != 0.0 || rotationalSkewY != 0.0 {
                let radiansX: Float = -CC_DEGREES_TO_RADIANS(rotationalSkewX)
                let radiansY: Float = -CC_DEGREES_TO_RADIANS(rotationalSkewY)
                cx = cosf(radiansX)
                sx = sinf(radiansX)
                cy = cosf(radiansY)
                sy = sinf(radiansY)
            }
            let needsSkewMatrix: Bool = (skewX != 0.0 || skewY != 0.0)
            var scaleFactor: Float = 1
            if scaleType == .Scaled {
                scaleFactor = CCSetup.sharedSetup().UIScale
            }
            // optimization:
            // inline anchor point calculation if skew is not needed
            // Adjusted transform calculation for rotational skew
            if !needsSkewMatrix && !anchorPointInPoints.isZero {
                x += cy * -anchorPointInPoints.x * scaleX * scaleFactor + -sx * -anchorPointInPoints.y * scaleY
                y += sy * -anchorPointInPoints.x * scaleX * scaleFactor + cx * -anchorPointInPoints.y * scaleY
            }
            // Build Transform Matrix
            // Adjusted transfor m calculation for rotational skew
            self.transform = GLKMatrix4Make(cy * scaleX * scaleFactor, sy * scaleX * scaleFactor, 0.0, 0.0, -sx * scaleY * scaleFactor, cx * scaleY * scaleFactor, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, x, y, vertexZ, 1.0)
            // XXX: Try to inline skew
            // If skew is needed, apply skew and then anchor point
            if needsSkewMatrix {
                let skewMatrix: GLKMatrix4 = GLKMatrix4Make(1.0, tanf(CC_DEGREES_TO_RADIANS(skewY)), 0.0, 0.0, tanf(CC_DEGREES_TO_RADIANS(skewX)), 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0)
                self.transform = GLKMatrix4Multiply(transform, skewMatrix)
                // adjust anchor point
                if !anchorPointInPoints.isZero {
                    self.transform = GLKMatrix4Translate(transform, -anchorPointInPoints.x, -anchorPointInPoints.y, 0.0)
                }
            }
            self.isTransformDirty = false
        }
        
        return transform
    }
    /** Returns the matrix that transform parent's space coordinates to the node's (local) space coordinates. The matrix is in points.
     @see nodeToParentMatrix
     */
    func parentToNodeMatrix() -> GLKMatrix4 {
        return GLKMatrix4Invert(self.nodeToParentMatrix(), nil)
    }
    
    /** Returns the world transform matrix. The matrix is in points.
     @see [GLKMatrix4](https://developer.apple.com/library/ios/documentation/GLkit/Reference/GLKMatrix4/index.html)
     @see nodeToParentMatrix
     @see worldToNodeMatrix
     */
    func nodeToWorldMatrix() -> GLKMatrix4 {
        var t: GLKMatrix4 = self.nodeToParentMatrix()
        var p = parent
        while p != nil {
            t = GLKMatrix4Multiply(p!.nodeToParentMatrix(), t)
            p = p!.parent
        }
        return t
    }
    
    /** Returns the inverse world transform matrix. The matrix is in points.
     @see [GLKMatrix4](https://developer.apple.com/library/ios/documentation/GLkit/Reference/GLKMatrix4/index.html)
     @see nodeToWorldTransform
     */
    func worldToNodeMatrix() -> GLKMatrix4 {
        return GLKMatrix4Invert(self.nodeToWorldMatrix(), nil)
    }
}