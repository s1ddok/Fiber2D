//
//  ViewportNode.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 13.10.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

internal func setViewport(_ minx: Float, _ miny: Float, _ maxx: Float, _ maxy: Float) {
    let context = CCMetalContext.current()
    let dst = context!.destinationTexture
    let dstw = Float(dst!.width)
    let dsth = Float(dst!.height)
    
    let minx = max(0, minx); let maxx = min(maxx, dstw)
    let miny = max(0, miny); let maxy = min(maxy, dsth)
    
    let viewport = MTLViewport(originX: Double(minx), originY: Double(dsth - maxy), width: Double(maxx - minx), height: Double(maxy - miny), znear: -1024, zfar: 1024)
    context!.currentRenderCommandEncoder.setViewport(viewport)
}

public class ViewportNode: Node {
    public var projection = Matrix4x4f.identity
    
    public var camera: Camera!
    
    public var contentNode: Node {
        get { return camera.children.first! }
        set {
            contentNode.removeFromParent()
            camera.add(child: newValue)
        }
    }
    convenience override init() {
        self.init(contentNode: Node())
    }
    
    init(contentNode: Node) {
        super.init()
        contentSize = Director.currentDirector!.viewSize
        camera = Camera(viewport: self)
        clipsInput = true
        add(child: camera)
        camera.add(child: contentNode)
        
        projection = Matrix4x4f.orthoProjection(for: self)
    }
    
    public static func centered(size: Size) -> ViewportNode {
        let viewport = ViewportNode()
        viewport.camera.position = size * 0.5
    
        let s = viewport.contentSizeInPoints
        viewport.projection = Matrix4x4f.ortho(left: -s.width / 2, right: s.width / 2,
                                               bottom: -s.height / 2, top: s.height / 2,
                                               near: 1024, far: -1024)
        return viewport
    }
    
    override func visit(_ renderer: CCRenderer, parentTransform: Matrix4x4f) {
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
        
        let minx = floorf(hw + hw*min(min(v0.x, v1.x), min(v2.x, v3.x)))
        let maxx = floorf(hw + hw*max(max(v0.x, v1.x), max(v2.x, v3.x)))
        let miny = floorf(hh + hh*min(min(v0.y, v1.y), min(v2.y, v3.y)))
        let maxy = floorf(hh + hh*max(max(v0.y, v1.y), max(v2.y, v3.y)))
        
        renderer.pushGroup()
        
        renderer.enqueue({ 
            setViewport(minx, miny, maxx, maxy)
            }, globalSortOrder: Int.min, debugLabel: "ViewportNode: Set viewport", threadSafe: true)
        
        let transform = camera.cameraMatrix
        sortAllChildren()
        for c in camera.children {
            c.visit(renderer, parentTransform: transform)
        }
        
        renderer.enqueue({ 
            setViewport(0, 0, fbSize.width, fbSize.height)
            }, globalSortOrder: Int.max, debugLabel: "ViewportNode: Reset viewport", threadSafe: true)
        renderer.popGroup(withDebugLabel: "ViewPort renderer", globalSortOrder: 0)
    }
}
