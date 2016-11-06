//
//  MainScene.swift
//
//  Created by Andrey Volodin on 06.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath
import Cocoa

class MainScene: Scene {
    
    var colorNode: ColorNode!
    var sprite: Sprite!
    
    var physicsSquares = [ColorNode]()
    
    let ground = ColorNode()
    
    var physicsSystem: PhysicsSystem!
    
    override init(size: Size) {
        super.init(size: size)
        
        let world = PhysicsWorld(rootNode: self)
        physicsSystem = PhysicsSystem(world: world)
        register(system: physicsSystem)
        
        world.contactDelegate = self
        
        sprite = Sprite(imageNamed: "circle.png")
        sprite.scale = 16.0
        sprite.position = p2d(0.5, 0.5)
        sprite.positionType = .normalized
        let action = ActionSkewTo(skewX: 15°, skewY: 45°).continously(duration: 15.0)
        sprite.run(action: action)
        add(child: sprite)
        
        colorNode = ColorNode()
        colorNode.color = Color(0.43, 0.17, 0.13, 1.0)
        colorNode.contentSize = Size(width: 64.0, height: 64.0)
        colorNode.position = p2d(0.5, 0.5)
        colorNode.positionType = .normalized
        var startPosition = p2d(0.1, 0.0)
        var colorNodes = [ColorNode]()
        for _ in 0..<13 {
            let colorNode = ColorNode()
            colorNode.color = .blue
            colorNode.contentSize = Size(width: 56.0, height: 56.0)
            colorNode.anchorPoint = p2d(0.5, 0.5)
            startPosition = startPosition + p2d(0.0, 0.1)
            colorNode.position = startPosition
            colorNode.positionType = .normalized
            colorNodes.append(colorNode)
            self.add(child: colorNode)
        }
        
        let rotate = ActionRotateTo(angle: 45°).continously(duration: 2.0)
        let skew   = ActionSkewTo(skewX: 30°, skewY: 30°).continously(duration: 1.0)
        let rotate2 = ActionRotateTo(angle: 0°).continously(duration: 2.0)
        let skew2   = ActionSkewTo(skewX: 15°, skewY: 10°).instantly
        
        let rotateBy = ActionRotateBy(angle: 15°).continously(duration: 1.0)
        
        let rotate3 = ActionRotateBy(angle: 90°)
        let move = ActionMoveBy(vec2(0.1, 0))
        let rotateAndMove = rotate3.and(move).continously(duration: 2.0)
        
        colorNodes[0].run(action: rotate)
        colorNodes[1].run(action: rotate.then(skew))
        colorNodes[2].run(action: rotate.then(skew).speed(0.50))
        colorNodes[3].run(action: rotate.then(skew).speed(0.50).ease(EaseSine.in))
        colorNodes[4].run(action: rotate.then(skew2).then(rotate2))
        colorNodes[5].run(action: rotate.and(skew))
        colorNodes[6].run(action: rotate.then(skew.and(rotate2)))
        colorNodes[7].run(action: rotateBy.repeatForever)
        //colorNodes[8].run(action: rotateBy.repeat(times: 6)
        //    .then(ActionCallBlock { print(colorNodes[8].position) }.instantly.repeat(times: 7)))
        colorNodes[8].run(action: rotateAndMove.then(ActionCallBlock { print(colorNodes[8].position) }.instantly))
        colorNodes[8].run(action: ActionMoveBy(vec2(0.0, -0.1)).continously(duration: 1.0))
        self.userInteractionEnabled = true
        print(Date())
        let _ = schedule(block: { (t:Timer) in
            print(Date())
            print(colorNodes[8].rotation)
            }, delay: 10.0)
        
        let material = PhysicsMaterial.default
        
        ground.contentSize = Size(1.0, 0.1)
        ground.contentSizeType = SizeType.normalized
        ground.color = .orange
        add(child: ground)
        
        let boxBody = PhysicsBody.box(size: ground.contentSizeInPoints, material: material)
        boxBody.isDynamic = false
        ground.add(component: boxBody)
        
        
        for j in 0..<10 {
            let physicsSquare = ColorNode()
            physicsSquare.color = .red
            physicsSquares.append(physicsSquare)
            physicsSquare.contentSize = Size(24.0, 24.0)
            let physicsBody = PhysicsBody.box(size: vec2(24.0, 24.0), material: material)
            physicsBody.isDynamic = true
            physicsSquare.add(component: physicsBody)
            physicsSquare.position = p2d(64.0 * Float(j), 256.0)
            
            if j % 2 == 0 {
                physicsSquare.add(component: UpdateComponent())
            } else {
                physicsSquare.add(component: FixedUpdateComponent())
            }
            
            add(child: physicsSquare)
        }
        
        let messageBubble = Sprite9Slice(imageNamed: "ninepatch_bubble.png")
        messageBubble.positionType = PositionType(xUnit: .points, yUnit: .points, corner: .topRight)
        messageBubble.contentSizeInPoints = messageBubble.contentSizeInPoints * 5.0
        //messageBubble.scale = 3.0
        messageBubble.position = p2d(256.0, 256.0)
        add(child: messageBubble)
    }
    
    override func onEnter() {
        super.onEnter()
        
        let rt = RenderTexture(width: 128, height: 128)
        rt.clearColor = .red
        rt.position = p2d(512, 512)
        
        rt.run(action: ActionMoveBy(vec2(150.0, 0)).continously(duration: 1.0)
                 .then(ActionMoveBy(vec2(-150.0, 0)).continously(duration: 1.0))
                 .repeatForever)
        let cn = ColorNode(color: .green, size: Size(32.0, 32.0))
        cn.positionType = .normalized
        cn.anchorPoint = p2d(0.5, 0.5)
        cn.run(action: ActionMoveTo(p2d(1, 1)).and(ActionRotateBy(angle: 90°)).continously(duration: 1.0)
            .then(ActionMoveTo(p2d(1, 0))     .and(ActionRotateBy(angle: 90°)).continously(duration: 1.0))
            .then(ActionMoveTo(p2d(0, 0))     .and(ActionRotateBy(angle: 90°)).continously(duration: 1.0))
            .repeatForever)
        rt.add(child: cn)
        
        
        let anotherSprite = Sprite(texture: rt.texture, rect: Rect(size: rt.contentSize), rotated: false)
        anotherSprite.run(action: ActionRotateBy(angle: 30°).continously(duration: 1.0).repeatForever)
        anotherSprite.position = p2d(128, 128)
        add(child: anotherSprite)
        add(child: rt)
    }
    
    override func mouseDown(_ theEvent: NSEvent, button: MouseButton) {
        //colorNode.positionInPoints = theEvent.location(in: self)
        //print(theEvent.location(in: self))
        
        for j in 0..<physicsSquares.count {
            //print(physicsSquares[j].physicsBody!.mass)
            //physicsSquares[j].physicsBody?.apply(force: vec2(0.0, Float(j) * 25.0))
            //physicsSquares[j].physicsBody!.isDynamic = !physicsSquares[j].physicsBody!.isDynamic
        }
        
        let physicsCircle = Sprite(imageNamed: "circle.png")
        let physicsBody = PhysicsBody.circle(radius: 6.0)
        physicsBody.isDynamic = true
        physicsBody.isGravityEnabled = true
        physicsCircle.position = theEvent.location(in: self)
        
        add(child: physicsCircle)
        physicsCircle.add(component: physicsBody)
    }
    
    override func scrollWheel(_ theEvent: NSEvent) {
        print("scroll")
    }
    
    override func mouseDragged(_ theEvent: NSEvent, button: MouseButton) {
        print("drag")
    }
    
    /*override func update(delta: Time) {
        colorNode.rotation += 1°
    }*/
}

extension Scene: PhysicsContactDelegate {
    public func didEnd(contact: PhysicsContact) {
        print("did end")
        
    }
    
    public func didBegin(contact: PhysicsContact) {
        print("did begin")
    }
}
