//
//  Node+Projection.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 02.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

extension Matrix4x4f {
    static func orthoProjection(for target: Node) -> Matrix4x4f {
        let size = target.contentSizeInPoints
        let w = Float(size.width)
        let h = Float(size.height)
        
        return Matrix4x4f.ortho(left: 0, right: w, bottom: 0, top: h, near: -1024, far: 1024)
    }
}
