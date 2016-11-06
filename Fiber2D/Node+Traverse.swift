//
//  Node+Traverse.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

extension Node {
    // This is not actually used anywhere now
    
    // purposefully undocumented: users needn't override/implement visit in their own subclasses
    /* Calls visit:parentTransform: using the current renderer and projection. */
    /*func visit() {
        guard let renderer = currentRenderer else {
            fatalError("Cannot call [Node visit] without a currently bound renderer.")
        }
        
        self.visit(renderer, parentTransform: renderer.projection)
    }*/
}
