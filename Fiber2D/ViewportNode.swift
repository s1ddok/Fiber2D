//
//  ViewportNode.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 13.10.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

public class ViewportNode: Node {
    public var projection = Matrix4x4f.identity
    
    /**
     *  Node that controls the camera's transform (position/rotation/zoom)
     */
    public var camera: Camera!
    
    /**
     *  User assignable node that holds the content that the viewport will show.
     */
    public var contentNode: Node {
        get { return camera.children.first! }
        set {
            contentNode.removeFromParent()
            camera.add(child: newValue)
        }
    }
    
    /**
     *  Create a viewport with the size of the screen and an empty contentNode.
     */
    convenience override init() {
        self.init(contentNode: Node())
    }
    
    /**
     *  Create a viewport with the given size and content node. Uses a orthographic projection. Initially the viewport is screen-sized.
     *
     *  @param contentNode Provide the content node. Its children are drawn into the viewport.
     *
     *  @return The ViewportNode
     */
    init(contentNode: Node) {
        super.init()
        contentSize = Director.currentDirector!.viewSize
        camera = Camera(viewport: self)
        clipsInput = true
        add(child: camera)
        camera.add(child: contentNode)
        
        projection = Matrix4x4f.orthoProjection(for: self)
    }
    
    // Convenience constructors to create screen sized viewports.
    public static func centered(size: Size) -> ViewportNode {
        let viewport = ViewportNode()
        viewport.camera.position = size * 0.5
    
        let s = viewport.contentSizeInPoints
        viewport.projection = Matrix4x4f.ortho(left: -s.width / 2, right: s.width / 2,
                                               bottom: -s.height / 2, top: s.height / 2,
                                               near: 1024, far: -1024)
        return viewport
    }
    
    override func visit(_ renderer: Renderer, parentTransform: Matrix4x4f) {
        guard visible else {
            return
        }
        
        let size = contentSizeInPoints
        let w = size.width
        let h = size.height
        let viewportTransform = parentTransform * nodeToParentMatrix
        let v0 = viewportTransform.multiplyAndProject(v: vec3(0, 0, 0))
        let v1 = viewportTransform.multiplyAndProject(v: vec3(w, 0, 0))
        let v2 = viewportTransform.multiplyAndProject(v: vec3(w, h, 0))
        let v3 = viewportTransform.multiplyAndProject(v: vec3(0, h, 0))
        
        let fbSize = Director.currentDirector!.viewSizeInPixels
        let hw = fbSize.width / 2.0
        let hh = fbSize.width / 2.0
        
        var minx = floorf(hw + hw*min(min(v0.x, v1.x), min(v2.x, v3.x)))
        var maxx = floorf(hw + hw*max(max(v0.x, v1.x), max(v2.x, v3.x)))
        var miny = floorf(hh + hh*min(min(v0.y, v1.y), min(v2.y, v3.y)))
        var maxy = floorf(hh + hh*max(max(v0.y, v1.y), max(v2.y, v3.y)))
        
        minx = max(0, minx)
        miny = max(0, miny)
        maxx = min(maxx, fbSize.width)
        maxy = min(maxy, fbSize.height)
        
        // TODO: Push group of draw calls with the viewport of (minx, miny, maxx - minx, maxy - miny)
        let transform = camera.cameraMatrix
        sortAllChildren()
        for c in camera.children {
            c.visit(renderer, parentTransform: transform)
        }
        
        // TODO: Pop group here (or push further, in bgfx terms), 
        // restore viewport to backbuffer's default
    }
}
