//
//  Texture+UV.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.12.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

public extension Texture {
    /// Returns an array of 4 elements that represents UV coordinates
    /// Return order: [bottom left, bottom right, top right, top left]
    public func uv(for rect: Rect, rotated: Bool, xFlipped flipX: Bool, yFlipped flipY: Bool) -> SpriteTexCoordSet {
        // Need to convert the texel coords for the texel stretch hack. (Bah)
        let scale = self.contentScale
        let rect = rect.scaled(by: scale)
        let sizeInPixels = self.sizeInPixels
        let atlasWidth = sizeInPixels.width
        let atlasHeight = sizeInPixels.height
        
        if rotated {
            var left   = rect.origin.x / atlasWidth
            var right  = (rect.origin.x + rect.size.height) / atlasWidth
            var bottom = rect.origin.y / atlasHeight
            var top    = (rect.origin.y + rect.size.width) / atlasHeight
            
            if flipX {
                swap(&top, &bottom)
            }
            if flipY {
                swap(&left, &right)
            }
            return SpriteTexCoordSet(bl: vec2(left, top),
                                     br: vec2(left, bottom),
                                     tr: vec2(right, bottom),
                                     tl: vec2(right, top))
        } else {
            var left   = rect.origin.x / atlasWidth
            var right  = (rect.origin.x + rect.size.width) / atlasWidth
            var bottom = rect.origin.y / atlasHeight
            var top    = (rect.origin.y + rect.size.height) / atlasHeight
            
            if flipX {
                swap(&left, &right)
            }
            if flipY {
                swap(&top, &bottom)
            }
            return SpriteTexCoordSet(bl: vec2(left, bottom),
                                     br: vec2(right, bottom),
                                     tr: vec2(right, top),
                                     tl: vec2(left, top))
        }
    }
}
