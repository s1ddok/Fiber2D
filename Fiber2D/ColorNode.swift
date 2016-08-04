//
//  ColorNode.swift
//
//  Created by Andrey Volodin on 06.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation

class ColorNode: RenderableNode {
    
    override func draw(_ renderer: CCRenderer, transform: GLKMatrix4) {
        let buffer = renderer.enqueueTriangles(2, andVertexes: 4, with: renderState, globalSortOrder: 0)
        
        let w = Float(contentSizeInPoints.width)
        let h = Float(contentSizeInPoints.height)
        let zero = GLKVector2(v: (0.0, 0.0))
        
        let blueColor = Color.blue.glkVector4
        let redColor = Color.red.glkVector4
        let greenColor = Color.green.glkVector4
        
        CCRenderBufferSetVertex(buffer, 0, CCVertex(position: GLKMatrix4MultiplyVector4(transform, GLKVector4Make(0, 0, 0, 1)), texCoord1: zero, texCoord2: zero, color: blueColor));
        CCRenderBufferSetVertex(buffer, 1, CCVertex(position: GLKMatrix4MultiplyVector4(transform, GLKVector4Make(w, 0, 0, 1)), texCoord1: zero, texCoord2: zero, color: redColor));
        CCRenderBufferSetVertex(buffer, 2, CCVertex(position: GLKMatrix4MultiplyVector4(transform, GLKVector4Make(w, h, 0, 1)), texCoord1: zero, texCoord2: zero, color: greenColor));
        CCRenderBufferSetVertex(buffer, 3, CCVertex(position: GLKMatrix4MultiplyVector4(transform, GLKVector4Make(0, h, 0, 1)), texCoord1: zero, texCoord2: zero, color: greenColor));
        
        CCRenderBufferSetTriangle(buffer, 0, 0, 1, 2)
        CCRenderBufferSetTriangle(buffer, 1, 0, 2, 3)
        
    }
}
