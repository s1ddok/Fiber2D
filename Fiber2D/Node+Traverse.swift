//
//  Node+Traverse.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation

extension Node {
    // purposefully undocumented: internal method, users should prefer to implement draw:transform:
    /* Recursive method that visit its children and draw them.
     * @param renderer The CCRenderer instance to use for drawing.
     * @param parentTransform The parent node's transform.
     */
    func visit(_ renderer: CCRenderer, parentTransform: GLKMatrix4) {
        // quick return if not visible. children won't be drawn.
        if !visible {
            return
        }
        self.sortAllChildren()
        let transform: GLKMatrix4 = GLKMatrix4Multiply(parentTransform, self.nodeToParentMatrix())
        var drawn: Bool = false
        
        for child in children {
            if !drawn && child.zOrder >= 0 {
                self.draw(renderer, transform: transform)
                drawn = true
            }
            child.visit(renderer, parentTransform: transform)
        }
        
        if !drawn {
            self.draw(renderer, transform: transform)
        }
    }
    
    // purposefully undocumented: users needn't override/implement visit in their own subclasses
    /* Calls visit:parentTransform: using the current renderer and projection. */
    func visit() {
        let renderer: CCRenderer! = CCRenderer.current()
        assert(renderer != nil, "Cannot call [Node visit] without a currently bound renderer.")
        var projection: GLKMatrix4 = GLKMatrix4Identity
        (renderer.globalShaderUniforms[CCShaderUniformProjection]! as! NSValue).getValue(&projection)
        self.visit(renderer, parentTransform: projection)
    }
}
