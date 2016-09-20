//
//  Scene.swift
//
//  Created by Andrey Volodin on 22.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation

/** Scene is a subclass of Node. The scene represents the root node of the node hierarchy.
 */
open class Scene: Node {
    
    override var scene: Scene {
        return self
    }
    
    override var director: Director! {
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
     The default value is an CCProjectionOrthographic delegate that goes from (0, 0) to the screen's size in points.
     
     @since 4.0.0
     */
    //var projectionDelegate: CCProjectionDelegate?
    /**
     Projection matrix for this scene. This value is overridden if the projectionDelegate is set.
     Defaults to the identity matrix.
     
     @since 4.0.0
     */
    var projection: Matrix4x4f {
        get {
            //return projectionDelegate?.projection ?? _projection
            return _projection }
        set { _projection = newValue }
    }
    private var _projection: Matrix4x4f!
    /// -----------------------------------------------------------------------
    /// @name Creating a Scene
    /// -----------------------------------------------------------------------
    /* Initialize the node. */
    
    override init() {
        super.init()
        let s = Director.currentDirector!.designSize
        self.anchorPoint = p2d(0.0, 0.0)
        self.contentSize = s
        self.colorRGBA = Color.black
        self._scheduler = Scheduler()
        //self.projectionDelegate = CCOrthoProjection(target: self)
        self._projection = Matrix4x4f(target: self)
        self.color = Color.black
    }
    
    override func onEnter() {
        super.onEnter()
        // mark starting scene as dirty, to make sure responder manager is updated
        director.responderManager.markAsDirty()
    }
    
    override func onEnterTransitionDidFinish() {
        super.onEnterTransitionDidFinish()
        // mark starting scene as dirty, to make sure responder manager is updated
        director.responderManager.markAsDirty()
    }
    
    //#if USE_PHYSICS
    public var physicsWorld: PhysicsWorld!
}
