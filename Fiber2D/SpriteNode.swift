//
//  SpriteNode.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.12.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

/**
 * SpriteNode draws a Texture on the screen.
 *
 * The default anchorPoint in SpriteNode is (0.5, 0.5).
 */
open class SpriteNode: Node {
    
    public var sprite: Sprite? {
        if let src = getComponent(by: SpriteRenderComponent.self) {
            return src.sprite
        }
        return nil
    }
    
    public convenience init(imageNamed: String) {
        self.init(sprite: Sprite(imageNamed: imageNamed))
    }
    
    public init(sprite: Sprite) {
        super.init()
        self.anchorPoint = p2d(0.5, 0.5)
        let src = SpriteRenderComponent(sprite: sprite)
        
        self.contentSizeInPoints = sprite.spriteFrame.untrimmedSize
        add(component: src)
    }
    
}
