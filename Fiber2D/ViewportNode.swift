//
//  ViewportNode.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 13.10.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

public class ViewportNode: Node {
    public var projection = Matrix4x4f.identity
    
    public var camera: Camera!
    
    init(contentNode: Node) {
        super.init()
        camera = Camera(viewport: self)
        clipsInput = true
        add(child: camera)
        camera.add(child: contentNode)
    }
}
