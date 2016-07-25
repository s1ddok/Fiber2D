//
//  Scene.swift
//
//  Created by Andrey Volodin on 22.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation

/** Scene is a subclass of Node. The scene represents the root node of the node hierarchy.
 */
class Scene: Node {
    
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

    override var scheduler: CCScheduler {
        get {
            return _scheduler
        }
        set {
            _scheduler = newValue
        }
    }
    
    private var _scheduler: CCScheduler!
    
    /**
     Delegate that calculates the projection matrix for this scene.
     The default value is an CCProjectionOrthographic delegate that goes from (0, 0) to the screen's size in points.
     
     @since 4.0.0
     */
    var projectionDelegate: CCProjectionDelegate?
    /**
     Projection matrix for this scene. This value is overridden if the projectionDelegate is set.
     Defaults to the identity matrix.
     
     @since 4.0.0
     */
    var projection: GLKMatrix4 {
        get { return projectionDelegate?.projection ?? _projection }
        set { _projection = newValue }
    }
    private var _projection: GLKMatrix4!
    /// -----------------------------------------------------------------------
    /// @name Creating a Scene
    /// -----------------------------------------------------------------------
    /* Initialize the node. */
    
    override init() {
        super.init()
        let s = Director.currentDirector()!.designSize
        self.anchorPoint = ccp(0.0, 0.0)
        self.contentSize = s
        self.colorRGBA = CCColor.blackColor()
        self._scheduler = CCScheduler()
        self.projectionDelegate = CCOrthoProjection(target: self)
        self._projection = GLKMatrix4Identity
        self.color = CCColor.blackColor()
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
}