//
//  RenderTextureSprite.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

internal class RenderTextureSprite: Sprite {
    weak var renderTexture: RenderTexture?
    
    internal var nodeToWorldTransform: Matrix4x4f {
        var t = self.nodeToParentMatrix
        var p: Node? = renderTexture
        while p != nil {
            t = p!.nodeToParentMatrix * t
            p = p!.parent
        }
        return t
    }
}
