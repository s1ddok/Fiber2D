//
//  Node+Traverse.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

extension Node {    
    // purposefully undocumented: users needn't override/implement visit in their own subclasses
    /* Calls visit:parentTransform: using the current renderer and projection. */
    func visit() {
        let renderer: CCRenderer! = CCRenderer.current()
        assert(renderer != nil, "Cannot call [Node visit] without a currently bound renderer.")
        var projection = Matrix4x4f.identity
        (renderer.globalShaderUniforms[CCShaderUniformProjection]! as! NSValue).getValue(&projection)
        self.visit(renderer, parentTransform: projection)
    }
}
