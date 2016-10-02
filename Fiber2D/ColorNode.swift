//
//  ColorNode.swift
//
//  Created by Andrey Volodin on 06.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

class ColorNode: RenderableNode {
    
    override func draw(_ renderer: Renderer, transform: Matrix4x4f) {
        var buffer = renderer.enqueueTriangles(count: 2, verticesCount: 4, state: renderState, globalSortOrder: 0)
        
        let w = Float(contentSizeInPoints.width)
        let h = Float(contentSizeInPoints.height)

        buffer.setVertex(index: 0, vertex: RendererVertex(position: transform * vec4(0, 0, 0, 1), texCoord1: vec2.zero, texCoord2: vec2.zero, color: Color.blue))
        buffer.setVertex(index: 1, vertex: RendererVertex(position: transform * vec4(w, 0, 0, 1), texCoord1: vec2.zero, texCoord2: vec2.zero, color: Color.red))
        buffer.setVertex(index: 2, vertex: RendererVertex(position: transform * vec4(w, h, 0, 1), texCoord1: vec2.zero, texCoord2: vec2.zero, color: Color.green))
        buffer.setVertex(index: 3, vertex: RendererVertex(position: transform * vec4(0, h, 0, 1), texCoord1: vec2.zero, texCoord2: vec2.zero, color: Color.green))
        
        buffer.setTriangle(index: 0, v1: 0, v2: 1, v3: 2)
        buffer.setTriangle(index: 1, v1: 0, v2: 2, v3: 3)
    }
}
