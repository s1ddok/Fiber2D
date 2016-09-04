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
        sprite.position = p2d(0.5, 0.5)
        sprite.positionType = CCPositionTypeNormalized
        //sprite.runAction(ActionSkewTo(duration: 15.0, skewX: 45.0, skewY: 45.0))
        let action = ActionSkewTo(skewX: 15.0, skewY: 45.0).continously(duration: 15.0)
        sprite.run(action: action)
        addChild(sprite)
        
        var startPosition = p2d(0.1, 0.0)
        var colorNodes = [ColorNode]()
        for _ in 0..<13 {
            colorNode = ColorNode()
            colorNode.contentSize = Size(width: 56.0, height: 56.0)
            colorNode.anchorPoint = p2d(0.5, 0.5)
            startPosition = startPosition + p2d(0.0, 0.1)
            colorNode.position = startPosition
            colorNode.positionType = CCPositionTypeNormalized
            colorNodes.append(colorNode)
            self.addChild(colorNode)
        }
        
        let rotate = ActionRotateTo(angle: 45°).continously(duration: 2.0)
        let skew   = ActionSkewTo(skewX: 30, skewY: 30).continously(duration: 1.0)
        let rotate2 = ActionRotateTo(angle: 0°).continously(duration: 2.0)
        let skew2   = ActionSkewTo(skewX: 15, skewY: 10).instantly
        
        let rotateBy = ActionRotateBy(angle: 15°).continously(duration: 1.0)
        
        colorNodes[0].run(action: rotate)
        colorNodes[1].run(action: rotate.then(skew))
        colorNodes[2].run(action: rotate.then(skew).speed(0.50))
        colorNodes[3].run(action: rotate.then(skew).speed(0.50).ease(EaseSine.in))
        colorNodes[4].run(action: rotate.then(skew2).then(rotate2))
        colorNodes[5].run(action: rotate.and(skew))
        colorNodes[6].run(action: rotate.then(skew.and(rotate2)))
        colorNodes[7].run(action: rotateBy.repeat(.Forever))
        colorNodes[8].run(action: rotateBy.repeat(.Times(6)))
        self.userInteractionEnabled = true
        print(Date())
        scheduleBlock({ (t:Timer) in
            print(Date())
            print(colorNodes[8].rotation)
            }, delay: 10.0)
    }
    
    override func onEnter() {
        super.onEnter()
        colorNode = ColorNode()
        colorNode.contentSize = Size(width: 64.0, height: 64.0)
        colorNode.position = p2d(0.5, 0.5)
        colorNode.positionType = CCPositionTypeNormalized
        
        let rt = RenderTexture(width: 64, height: 64)
        rt.begin()
        colorNode.removeFromParent()
        colorNode.visit()
        rt.end()
        
        //colorNode.runAction(repeatForever!)
        addChild(colorNode)
        rt.sprite.positionType = CCPositionTypeNormalized
        rt.sprite.position = p2d(0.5, 0.5)
        rt.sprite.opacity = 0.5
        self.addChild(rt.sprite)
        
        print(sprite.active)
        
        
    }
    override func mouseDown(_ theEvent: NSEvent, button: MouseButton) {
        colorNode.positionInPoints = theEvent.location(in: self)
        print(theEvent.location(in: self))
    }
    
    override func update(delta: Time) {
        colorNode.rotation += 1°
    }
}
