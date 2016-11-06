//
//  ViewportScene.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 15.10.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath
import Cocoa

class CustomBehaviour: ComponentBase, Updatable {
    let vps: ViewportScene
    
    init(v: ViewportScene) {
        vps = v
    }
    
    func update(delta: Time) {
        vps.viewport.camera.position = vps.cn.positionInPoints
    }
}

class ViewportScene: Scene {
    var viewport: ViewportNode!
    let cn = Sprite(imageNamed: "circle.png")//ColorNode()
    
    override init(size: Size) {
        super.init(size: size)
        
        let container = Node()
        container.contentSizeInPoints = Size(1048, 1048)
        
        //cn.contentSize = Size(62.0, 32.0)
        cn.positionType = .normalized
        cn.position = p2d(0.5, 0.5)
        //cn.anchorPoint = cn.position
        //cn.color = .red
        container.add(child: cn)
        viewport = ViewportNode.centered(size: size)
        viewport.contentNode = container
        viewport.userInteractionEnabled = false
        add(child: viewport)
        
        let bl = ColorNode()
        bl.contentSize = Size(32.0, 32.0)
        bl.position = .zero
        bl.color = .blue
        container.add(child: bl)
        
        let tr = ColorNode()
        tr.contentSize = Size(32.0, 32.0)
        tr.position = p2d(1.0, 1.0)
        tr.positionType = .normalized
        tr.color = .blue
        container.add(child: tr)
        
        let placeholder = ColorNode()
        placeholder.contentSizeType = .normalized
        placeholder.contentSize = Size(1.0, 1.0)
        //container.add(child: placeholder)
        add(component: CustomBehaviour(v: self))
        userInteractionEnabled = true
    }
    
    override func mouseDown(_ theEvent: NSEvent, button: MouseButton) {
        
        viewport.camera.position = viewport.camera.position - vec2(32.0, 32.0)
        print(viewport.camera.children.first!.positionInPoints)
    }
    
    override func mouseDragged(_ theEvent: NSEvent, button: MouseButton) {
        viewport.camera.positionInPoints = theEvent.location(in: self)
    }
    
    override func keyDown(_ theEvent: NSEvent) {
        
        switch theEvent.keyCode {
        /*case 123:
            viewport.camera.positionInPoints = viewport.camera.positionInPoints - vec2(10.0, 0.0)
        case 124:
            viewport.camera.positionInPoints = viewport.camera.positionInPoints + vec2(10.0, 0.0)
        case 125:
            viewport.camera.positionInPoints = viewport.camera.positionInPoints - vec2(0.0, 10.0)
        case 126:
            viewport.camera.positionInPoints = viewport.camera.positionInPoints + vec2(0.0, 10.0)
        default:
            ()*/
         case 123:
         cn.position = cn.position - vec2(0.01, 0.0)
         case 124:
         cn.position = cn.position + vec2(0.01, 0.0)
         case 125:
         cn.position = cn.position - vec2(0.0, 0.01)
         case 126:
         cn.position = cn.position + vec2(0.0, 0.01)
         default:
         ()
        }
    }
}
