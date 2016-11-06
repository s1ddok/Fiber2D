//
//  Scene.swift
//
//  Created by Andrey Volodin on 22.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

/** Scene is a subclass of Node. The scene represents the root node of the node hierarchy.
 */
open class Scene: Node {
    // Override these with self and stored properties
    override public var scene: Scene {
        return self
    }
    
    override public var director: Director! {
        get {
            return _director
        }
        set {
            _director = newValue
        }
    }
    
    private var _director: Director!

    override var scheduler: Scheduler {
        get {
            return _scheduler
        }
        set {
            _scheduler = newValue
        }
    }
    
    private var _scheduler: Scheduler!
    
    /**
     Delegate that calculates the projection matrix for this scene.
     The default value is an ProjectionOrthographic delegate that goes from (0, 0) to the screen's size in points.
     */
    //var projectionDelegate: ProjectionDelegate?
    
    /**
     Projection matrix for this scene. This value is overridden if the projectionDelegate is set.
     Defaults to the identity matrix.
     */
    public var projection: Matrix4x4f {
        get {
            //return projectionDelegate?.projection ?? _projection
            return _projection }
        set { _projection = newValue }
    }
    private var _projection: Matrix4x4f!
    
    internal(set) public var systems = [System]()
    
    /// @name Creating a Scene
    
    /// Initialize the scene.
    public init(size: Size) {
        super.init()
        self.contentSize = size
        self.anchorPoint = .zero
        self.colorRGBA   = .black
        self.color       = .black
        self._scheduler  = Scheduler()
        self._projection = Matrix4x4f.orthoProjection(for: self)
    }
}
