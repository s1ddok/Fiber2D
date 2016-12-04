//
//  Sprite9SliceNode.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 05.12.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

open class Sprite9SliceNode: Node {
    public var sprite: Sprite9Slice? {
        if let src = renderComponent as? Sprite9SliceRenderComponent {
            return src.sprite
        }
        return nil
    }
    
    public convenience init(imageNamed: String) {
        self.init(sprite: Sprite9Slice(imageNamed: imageNamed))
    }
    
    public init(sprite: Sprite9Slice) {
        super.init()
        self.anchorPoint = p2d(0.5, 0.5)
        let src = Sprite9SliceRenderComponent(sprite: sprite)
        
        self.contentSizeInPoints = sprite.spriteFrame.untrimmedSize
        // So that didSet will be called
        defer {
            self.renderComponent = src
        }
    }
}
