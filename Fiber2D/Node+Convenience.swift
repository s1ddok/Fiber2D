//
//  Node+Convenience.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

extension Node {
    /** The CCView this node is a member of, accessed via the scene and director associated with this node.
     
     @see CCView */
    var view: DirectorView? {
        return director?.view
    }
    
    /** The CCDirector this node is a member of, accessed via the node's scene.
     
     @see CCDirector */
    var director: Director? {
        return scene?.director
    }
    
}
