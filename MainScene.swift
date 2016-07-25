//
//  MainScene.swift
//
//  Created by Andrey Volodin on 06.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation

class MainScene: Scene {
    
    var colorNode: ColorNode!
    var sprite: Sprite!
    override init() {
        super.init()
        
        sprite = Sprite(imageNamed: "image.jpeg")
        sprite.scale = 6.0
        sprite.position = ccp(0.5, 0.5)
        sprite.positionType = CCPositionTypeNormalized
        sprite.runAction( CCActionRepeatForever(action: CCActionRotateBy(duration: 3.0, angle: 60.0)))
        addChild(sprite)
        
        self.userInteractionEnabled = true
    }
    
    override func onEnter() {
        super.onEnter()
        colorNode = ColorNode()
        colorNode.contentSize = CGSize(width: 64.0, height: 64.0)
        colorNode.position = ccp(0.5, 0.5)
        colorNode.positionType = CCPositionTypeNormalized
        
        let repeatForever = CCActionRepeatForever(action: CCActionRotateBy(duration: 3.0, angle: 60.0))
        
        let rt = RenderTexture(width: 64, height: 64)
        rt.begin()
        colorNode.removeFromParent()
        colorNode.visit()
        rt.end()
        
        colorNode.runAction(repeatForever)
        addChild(colorNode)
        rt.sprite.positionType = CCPositionTypeNormalized
        rt.sprite.position = ccp(0.5, 0.5)
        rt.sprite.opacity = 0.5
        self.addChild(rt.sprite)
        
        print(sprite.active)
        
    }
    override func mouseDown(theEvent: NSEvent, button: MouseButton) {
       // print(theEvent.locationInNode(self))
    }
}