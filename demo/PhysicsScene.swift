//
//  PhysicsScene.swift
//  Fiber2D-demo
//
//  Created by Andrey Volodin on 28.12.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import Fiber2D
import SwiftMath

public class PhysicsScene: Scene {
    
    var physicsSystem: PhysicsSystem!
    
    override init(size: Size) {
        super.init(size: size)
        
        let material = PhysicsMaterial.default
        let colors: [Color] = [.red, .blue, .green, .orange]
        
        let world = PhysicsWorld(rootNode: self)
        physicsSystem = PhysicsSystem(world: world)
        register(system: physicsSystem)

        let ground = ColorNode()
        ground.contentSize = Size(1.0, 0.1)
        ground.contentSizeType = SizeType.normalized
        ground.color = .orange
        add(child: ground)

        let boxBody = PhysicsBody.box(size: ground.contentSizeInPoints, material: material)
        boxBody.isDynamic = false
        ground.add(component: boxBody)
        
        let pikeSize = Size(620, 32)
        let pike1 = ColorNode()
        pike1.contentSize = pikeSize
        pike1.color       = .white
        pike1.position    = p2d(320, 400)
        add(child: pike1)
        let boxBody1 = PhysicsBody.box(size: pikeSize, material: material)
        boxBody1.isDynamic = false
        pike1.add(component: boxBody1)

        for _ in 0...10 {
            let node = Node()
            node.contentSize = Size(128, 128)
            node.position = p2d(0.5, 0.5)
            node.positionType = .normalized
            node.rotation = Angle(degrees: Float.random(0, 180))
            
            let colorNode = ColorNode()
            colorNode.position = p2d(0.5, 1.5)
            colorNode.positionType = .normalized
            colorNode.color = colors[Int.random(0, colors.count - 1)]
            colorNode.contentSize = Size(32, 32)
            node.add(child: colorNode)
            
            let rotateForever = ActionRotateBy(angle: 15°).continously(duration: Float.random(0.5, 2)).repeatForever
            node.run(action: rotateForever)
            add(child: node)
        }
        
        let spawnSquares = ActionCallBlock { [unowned self] in
            let squareSize = Size(22, 22)
            let physicsSquare = ColorNode()
            physicsSquare.color = colors[Int.random(0, colors.count - 1)]
            physicsSquare.contentSize = squareSize
            let physicsBody = PhysicsBody.box(size: squareSize, material: material)
            physicsBody.isDynamic = true
            physicsBody.isGravityEnabled = true
            physicsSquare.add(component: physicsBody)
            
            physicsSquare.position = self.contentSize * vec2(Float.random(0, 1), 1.0)
            self.add(child: physicsSquare)
            }.instantly.then(ActionWait(for: 1.0)).repeat(times: 100)
        
        self.run(action: spawnSquares)
        
        
        
    }
}
