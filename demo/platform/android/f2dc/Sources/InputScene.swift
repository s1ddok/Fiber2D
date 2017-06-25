//
//  InputScene.swift
//  Fiber2D-demo
//
//  Created by Andrey Volodin on 25.01.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//

import SwiftMath
import Fiber2D

public class DragTransformComponent: Responder {
    public override func inputDragged(_ input: Input) {
        let sceneSize = owner!.scene!.contentSizeInPoints
        let inputLocation = input.location(in: self.owner!.scene!)
        self.owner!.position = inputLocation
        self.owner!.rotation = Angle(degrees: 180 * input.screenPosition.x / sceneSize.width)
        self.owner!.scale = 2 * input.screenPosition.y / sceneSize.height
    }
}

public class InputScene: Scene {
    
    public override init(size: Size) {
        super.init(size: size)
        
        let square = ColorNode(color: .red, size: Size(64, 64))
        square.anchorPoint = vec2(0.5, 0.5)
        square.position = boundingBox.size * 0.5
        square.responder = DragTransformComponent()
        self.add(child:square)
    }
}
