//
//  ViewportScene.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 15.10.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

class ViewportScene: Scene {
    var viewport: ViewportNode!
    
    override init(size: Size) {
        super.init(size: size)
        
        let container = Node()
        container.contentSizeInPoints = Size(1048, 1048)
        let cn = ColorNode()
        cn.contentSize = Size(62.0, 32.0)
        cn.positionType = .normalized
        cn.position = p2d(0.5, 0.5)
        container.add(child: cn)
        viewport = ViewportNode(contentNode: container)
        //viewport.camera.position = cn.positionInPoints
        viewport.userInteractionEnabled = false
        //viewport.zOrder = 99
        add(child: viewport)
        
        userInteractionEnabled = true
    }
    
    override func mouseDown(_ theEvent: NSEvent, button: MouseButton) {
        
        viewport.camera.position = viewport.camera.position - vec2(32.0, 32.0)
        print(viewport.camera.children.first!.positionInPoints)
    }
    
    override func mouseDragged(_ theEvent: NSEvent, button: MouseButton) {
        viewport.camera.positionInPoints = theEvent.location(in: self)
    }
    
    //func update(delta: Time) {
    //}
}
