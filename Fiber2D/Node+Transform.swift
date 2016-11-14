//
//  Node+Transform.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation
import SwiftMath

public extension Node {
    
    @inline(__always)
    internal func calculateTransformIfNeeded() {
        guard isTransformDirty else {
            return
        }
        
        // Get content size
        // Convert position to points
        var positionInPoints: p2d
        if positionType.isBasicPoints {
            // Optimization for basic points (most common case)
            positionInPoints = position
        } else {
            positionInPoints = self.positionInPoints
        }
        
        // Get x and y
        var x = positionInPoints.x
        var y = positionInPoints.y
        // Rotation values
        // Change rotation code to handle X and Y
        // If we skew with the exact same value for both x and y then we're simply just rotating
        var cx: Float = 1
        var sx: Float = 0
        var cy: Float = 1
        var sy: Float = 0
        if rotationalSkewX != .zero || rotationalSkewY != .zero {
            sincos(-rotationalSkewX, &sx, &cx)
            sincos(-rotationalSkewY, &sy, &cy)
        }
        
        let needsSkewMatrix = skewX != .zero || skewY != .zero
        var scaleFactor: Float = 1
        if scaleType == .scaled {
            scaleFactor = Setup.shared.UIScale
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
        self.transform = Matrix4x4f(vec4(cy * scaleX * scaleFactor,  sy * scaleX * scaleFactor, 0.0, 0.0),
                                    vec4(-sx * scaleY * scaleFactor, cx * scaleY * scaleFactor, 0.0, 0.0),
                                    vec4(0, 0, 1,       0),
                                    vec4(x, y, vertexZ, 1))
        // XXX: Try to inline skew
        // If skew is needed, apply skew and then anchor point
        if needsSkewMatrix {
            let skewMatrix = Matrix4x4f(vec4(1.0, tan(skewY), 0.0, 0.0),
                                        vec4(tan(skewX), 1.0, 0.0, 0.0),
                                        vec4(0.0, 0.0, 1.0, 0.0),
                                        vec4(0.0, 0.0, 0.0, 1.0))
            self.transform = transform * skewMatrix
            // adjust anchor point
            if !anchorPointInPoints.isZero {
                self.transform = transform.translated(by: vec3(-anchorPointInPoints))
            }
        }
        
        isTransformDirty = false
    }
    
    /** Returns the matrix that transform parent's space coordinates to the node's (local) space coordinates. The matrix is in points.
     @see nodeToParentMatrix
     */
    public var parentToNodeMatrix: Matrix4x4f {
        return nodeToParentMatrix.inversed
    }
    
    /** Returns the world transform matrix. The matrix is in points.
     @see nodeToParentMatrix
     @see worldToNodeMatrix
     */
    public var nodeToWorldMatrix: Matrix4x4f {
        var t = self.nodeToParentMatrix
        var p = parent
        while p != nil {
            t = p!.nodeToParentMatrix * t
            p = p!.parent
        }
        return t
    }
    
    /** Returns the inverse world transform matrix. The matrix is in points.
     @see nodeToWorldTransform
     */
    public var worldToNodeMatrix: Matrix4x4f {
        return nodeToWorldMatrix.inversed
    }
}
