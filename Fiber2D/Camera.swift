//
//  Camera.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 09.10.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

/**
 * The type of camera.
 */
public enum CameraType {
    case orthographic
}

/**
 * Defines a camera.
 */
public class Camera: Node {
    /**
     * The type of camera.
     *
     * @return The camera type.
     */
    public let type: CameraType = .orthographic
    
    public unowned let viewport: ViewportNode
    
    init(viewport: ViewportNode) {
        self.viewport = viewport
    }
    
    override public var contentSize: Size {
        get { return parent!.contentSize }
        set {}
    }
    
    override public var contentSizeType: SizeType {
        get { return parent!.contentSizeType }
        set {}
    }
    
    override public var contentSizeInPoints: Size {
        get { return parent!.contentSizeInPoints }
        set {}
    }
    
    // Override nodeToParentMatrix so input (like touches) in the viewport can be transformed into the node space of the content of the viewport.
    public override var nodeToParentMatrix: Matrix4x4f {
        let cs = viewport.contentSizeInPoints * 0.5
        let hw = cs.width
        let hh = cs.height
        
        // Scale and translate matrix to convert from clip coordiates to viewport internal coordinates
        let toProj = Matrix4x4f(vec4(hw,  0.0, 0.0, 0.0),
                                vec4(0.0, hh,  0.0, 0.0),
                                vec4(0.0, 0.0, 1.0, 0.0),
                                vec4(hw,  hh,  0.0, 1.0))
        return toProj * cameraMatrix
    }
    
    // Camera matrix is used for drawing the contents of the viewport, relative to the camera.
    public var cameraMatrix: Matrix4x4f {
        let cameraTransform = super.nodeToParentMatrix.inversed
        return viewport.projection * cameraTransform
    }

}
