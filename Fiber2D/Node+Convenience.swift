//
//  Node+Convenience.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

public extension Node {
    /** The scene this node is added to, or nil if it's not part of a scene.
     
     @note The scene property is nil during a node's init methods. The scene property is set only after addChild: was used to add it
     as a child node to a node that already is in the scene.
     @see Scene */
    public var scene: Scene? {
        return parent?.scene
    }
    
    /** The DirectorView this node is a member of, accessed via the scene and director associated with this node.
     
     @see DirectorView */
    public var view: DirectorView? {
        return director?.view
    }
    
    /** The Director this node is a member of, accessed via the node's scene.
     
     @see Director */
    public var director: Director? {
        return scene?.director
    }
    
}
