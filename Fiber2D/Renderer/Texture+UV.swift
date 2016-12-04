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
    public func uv(for rect: Rect, rotated: Bool, xFlipped flipX: Bool, yFlipped flipY: Bool) -> [Vector2f] {
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
            return [vec2(left, top),
                    vec2(left, bottom),
                    vec2(right, bottom),
                    vec2(right, top)]
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
            return [vec2(left, bottom),
                    vec2(right, bottom),
                    vec2(right, top),
                    vec2(left, top)]
        }
    }
}
