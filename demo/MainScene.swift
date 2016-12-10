//
//  MainScene.swift
//
//  Created by Andrey Volodin on 06.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath
import Cocoa
import Fiber2D

fileprivate func createRT(size: Size, clearColor: Color, geometryColor: Color = .green) -> RenderTexture {
    let rt = RenderTexture(width: UInt(size.width), height: UInt(size.height))
    rt.clearColor = clearColor
    
    let cn = ColorNode(color: geometryColor, size: size * 0.2)
    cn.positionType = .normalized
    cn.anchorPoint = p2d(0.5, 0.5)
    cn.run(action: ActionMoveTo(p2d(1, 1)).and(ActionRotateBy(angle: 90°)).continously(duration: 1.0)
        .then(ActionMoveTo(p2d(1, 0))     .and(ActionRotateBy(angle: 90°)).continously(duration: 1.0))
        .then(ActionMoveTo(p2d(0, 0))     .and(ActionRotateBy(angle: 90°)).continously(duration: 1.0))
        .repeatForever)
    
    rt.add(child: cn)

    return rt
}

fileprivate func createChildRT(size: Size, clearColor: Color,geometryColor: Color = .white) -> RenderTexture {
    let rtChild = createRT(size: size * 0.5, clearColor: clearColor, geometryColor: geometryColor)
    rtChild.positionType = .normalized
    rtChild.position = p2d(0.5, 0.5)
    
    rtChild.run(action: ActionRotateBy(angle: .pi_4).continously(duration: Time.random(1.0, 4.0)).repeatForever)
    
    return rtChild
}

class MainScene: Scene {
    
    var colorNode: ColorNode!
    var sprite: Sprite!
    
    var physicsSquares = [ColorNode]()
    
    let ground = ColorNode()
    
    var physicsSystem: PhysicsSystem!
    
    override init(size: Size) {
        super.init(size: size)
        
        self.responder = MainSceneResponder()
        
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
        
        onEnter.subscribeOnce(on: self) { [unowned self] in
            let rt = createRT(size: Size(128.0), clearColor: .red)
            rt.position = p2d(512, 512)
            rt.run(action: ActionMoveBy(vec2(150.0, 0)).continously(duration: 1.0)
                .then(ActionMoveBy(vec2(-150.0, 0)).continously(duration: 1.0))
                .repeatForever)
            let anotherSprite = Sprite(texture: rt.texture, rect: Rect(size: rt.contentSize), rotated: false)
            anotherSprite.run(action: ActionRotateBy(angle: 30°).continously(duration: 1.0).repeatForever)
            anotherSprite.position = p2d(128, 128)
            self.add(child: anotherSprite)
            self.add(child: rt)
            
            let colors: [Color] = [ .red, .blue, .purple ]
            let positionType = PositionType(xUnit: .points, yUnit: .points, corner: .bottomRight)
            let baseSize = Size(128, 128)
            var initialPosition = p2d(0, baseSize.height)
            for _ in 0...4 {
                let rt = createRT(size: baseSize, clearColor: colors[Int.random(0, colors.count - 1)])
                rt.positionType = positionType
                initialPosition.width = initialPosition.width + baseSize.width + 24.0
                rt.position = initialPosition
                self.add(child: rt)
                
                let rtChild = createChildRT(size: baseSize, clearColor: .gray, geometryColor: .white)
                rt.add(child: rtChild)
                
                if Int.random() % 2 == 0 {
                    let anotherChild = createChildRT(size: baseSize, clearColor: .darkGray, geometryColor: .white)
                    anotherChild.position = .zero
                    anotherChild.positionType = .points
                    rt.add(child: anotherChild)
                }
            }
        }
    }
    
}

public class MainSceneResponder: Responder {
    override public func inputBegan(_ input: Input) {
        let physicsCircle = Sprite(imageNamed: "circle.png")
        let physicsBody = PhysicsBody.circle(radius: 6.0)
        physicsBody.isDynamic = true
        physicsBody.isGravityEnabled = true
        physicsCircle.position = input.location(in: owner!)
        
        owner!.add(child: physicsCircle)
        physicsCircle.add(component: physicsBody)
    }
    
    override func scrollWheel(_ theEvent: NSEvent) {
        print("scroll")
    }
    
    override public func inputDragged(_ input: Input) {
        print("drag")
    }
}

extension MainScene: PhysicsContactDelegate {
    public func didEnd(contact: PhysicsContact) {
        print("did end")
        
    }
    
    public func didBegin(contact: PhysicsContact) {
        print("did begin")
    }
}
