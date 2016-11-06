//
//  Node.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

/** Node is the base class for all objects displayed by Fiber2D. Node handles transformations, can have a content size and provides a coordinate system
 for its child nodes.
 
 ### Node Hierarchy
 
 Nodes are hierachically organized in a tree with a Scene as its root node. This is often referred to as *scene graph*, *node hierarchy* or *node tree*.
 
 By default every node can have other nodes as child nodes. Some node classes restrict child nodes to a specific instance type, or don't allow child nodes at all.
 
 A child node is positioned and rotated relative to its parent. Some properties of the parent node are "inherited" by child nodes, for example: scale, visible, paused.
 Other properties are only "inherited" if enabled, see cascadeOpacityEnabled for example.
 
 ### Draw Order
 
 Draw order of nodes is controlled primarily by their order in the node hierarchy. The parent node is drawn first, followed by its child nodes in the order they
 were added.
 
 You can fine-tune draw order via the zOrder property. By default all nodes have a zOrder of 0. Nodes with lower zOrder are drawn before nodes with higher zOrder.
 This applies only to nodes in the same level (sibling nodes) and their parent node, as the zOrder is relative to the zOrder of the parent.
 
 Assuming you have two parent nodes A and B with zOrder 0 and they are drawn in the order A first, then B. Then all of the children of parent B will be drawn
 in front of any child node of parent A. If B's zOrder is changed to -1, then parent B and all of its children will be drawn behind parent A and its children.
 
 ### Scheduling Events / Timers
 
 You can use the various schedule methods of a node, such as schedule(block:delay:).
 
 **Warning:** Any non-Fiber2D scheduling methods will be unaffected by the node's paused state and may run in indeterminate order, possibly causing rendering
 glitches and timing bugs. It is therfore strongly discouraged to use NSTimer, `performSelector:afterDelay:` or Grand Central Disptach (GCD) `dispatch_xxx` methods
 to time/schedule tasks in Fiber2D.
 
 #### Pausing
 
 It is common practice to pause the topmost node of a layer whose contents you want to pause. For instance you should have a gameLayer node that you can use
 to pause the entire game, while the hudLayer and pauseMenuLayer nodes may not need to or shouldn't be paused in order to continue animations and allowing the
 user to interact with a pause menu.
 
 ### Input Handling
 
 Any Node or subclass can receive touch and mouse events, if enabled. See the Responder super class for more information.
 
 ### Position and Size Types
 
 Coordinates in the Node coordinate system are by default set in points by the position property. The point measurement provides a way to handle different
 screen pixel densities. For instance, on a Retina device one point corresponds to two pixels, but on non-Retina devices point and pixel resolution are identical.
 
 By using the positionType property you can specify how a node's position is interpreted. For instance, if you set the type to PositionTypeNormalized a
 position value of (0.5, 0.5) will place the node in the center of its parent's container. The container is specified by the parent's contentSize.
 
 It's also possible to set positions relative to the different corners of the parent's container. The PositionType has three components, xUnit, yUnit and corner.
 The corner can be any reference corner of the parent's container and the xUnit and yUnit can be any of the following:
 
 - .points - This is the default, the position value will be in points.
 - .scaled - The position is scaled by the UIScaleFactor as defined by Director. This is very useful for scaling up game play without changing the game logic.
 E.g. if you want to support both phones and tablets in native resolutions.
 - .normalized - Using the normalized type allows you to position object in relative to the parents container. E.g. it can be used to center nodes
 on the screen regardless of the device type your game is running on.
 
 Similarily to how you set a node's position and positionType you can also set it's contentSize and contentSizeType. However, some classes doesn't allow you
 to set these directly. For instance, the Sprite sets its contentSize depending on the size of its texture and for descendants of Control you should
 set the preferredSize and preferredSizeType rather than changing their contentSize directly. The SizeType has two components widthUnit and heightUnit
 which can be any of the following:
 
 - .points - This is the default, the size will be in points
 - .scaled - The size is scaled by the UIScaleFactor.
 - .normalized - The content size will be set as a normalized value of the parent's container.
 - .inset - The content size will be the size of it's parent container, but inset by a number of points.
 - .insetScaled - The content size will be the size of it's parent container, but inset by a number of points multiplied by the UIScaleFactor.
 
 Even if the positions and content sizes are not set in points you can use actions to animate the nodes. See the examples and tests for more information on
 how to set positions and content sizes, or use SpriteBuilder to easily play around with the settings. There are also more positioning options available
 by using Layout and LayoutBox.
 
 #### Prefer to use ..InPoints
 
 There are typically two properties of each property supporting a "type". For instance the position property returns the raw values whose meaning
 depends on positionType, while positionInPoints will return the position in points regardless of positionType. It is recommended to use the "inPoints"
 variants of properties if you expect the values to be in points.
 
 Otherwise your code will break if you subsequently change the positionType to something other than points (ie UIPoints or Normalized).
 
 ### Subclassing Notes
 
 A common pattern in building a Fiber2D game is to subclass Node, add it to a Scene and override the methods for handling user input.
 Consider each node subclass as being the view in a MVC model, but it's also the controller for this node and perhaps even the node's branch of the node tree.
 The model can also be represented by the node subclass itself, or made separate (M-VC model).
 
 A separate model could simply be any NSObject class initialized by the node subclass and assigned to an ivar/property.
 
 An advanced subclassing style aims to minimize subclassing node classes except for Node itself. A Node subclass acts as the controller for its node tree,
 with one or more child nodes representing the controller node's views. This is particularly useful for composite nodes, such as a player
 with multiple body parts (head, torso, limbs), attachments (armor, weapons) and effects (health bar, name label, selection rectangle, particle effects).
 */
open class Node: Responder, Prioritized, Pausable, Enterable, Exitable {
    
    // MARK: Convenience
    /// Should be in +Convenience, but are being overriden in Scene
    
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
    
    /** Scheduler used to schedule all "updates" and timers. */
    internal var scheduler: Scheduler? {
        return scene?.scheduler
    }
    
    // MARK: Components
    /// Array of components added to the node
    internal(set) public var components = [Component]()
    internal var fixedUpdatableComponents = [FixedUpdatable & Tagged]()
    internal var updatableComponents      = [Updatable      & Tagged]()
    
    // MARK: Hierarchy
    internal weak var _parent: Node?
    /** Array of child nodes. Used to enumerate child nodes. */
    internal(set) public var children = [Node]()

    // MARK: Transforms
    internal var isTransformDirty = true
    internal var transform = Matrix4x4f.identity
    
    // MARK: Position
    
    /// @name Position
    
    /** Position (x,y) of the node in the units specified by the positionType property.
     The distance is measured from one of the corners of the node's parent container, which corner is specified by the positionType property.
     Default setting is referencing the bottom left corner in points.
     @see positionInPoints
     @see positionType */
    public var position = Point.zero {
        didSet {
            isTransformDirty = true
        }
    }
    
    /** Position (x,y) of the node in points from the bottom left corner.
     @see position */
    public var positionInPoints: Point {
        get {
            return convertPositionToPoints(position, type: positionType)
        }
        set {
            position = convertPositionFromPoints(newValue, type: positionType)
        }
    }
    
    /** Defines the position type used for the position property. Changing the position type affects the meaning of the values
     assigned to the position property and allows you to change the referenceCorner relative to the parent container.
     It also allows position to be interpreted as "UIPoints", which are scaled by Director.UIScaleFactor.
     See "Coordinate System and Positioning" in Class Overview for more information.
     @see PositionType, PositionUnit, PositionReferenceCorner
     @see position
     @see positionInPoints */
    public var positionType = PositionType.points {
        didSet {
            isTransformDirty = true
        }
    }
    
    // MARK: Rotation and skew
    
    /// @name Rotation and Skew
    
    /** The rotation (angle) of the node in degrees. Rotation is relative to the parent node's rotation.
     0 is the default rotation angle. Positive values rotate node clockwise. */
    public var rotation: Angle {
        get {
            assert(rotationalSkewX == rotationalSkewY, "Node#rotation. rotationalSkewX != rotationalSkewY. Don't know which one to return")
            return rotationalSkewX
        }
        set {
            rotationalSkewX = newValue
            rotationalSkewY = newValue
        }
    }
    /** The rotation (angle) of the node in degrees. 0 is the default rotation angle. Positive values rotate node clockwise.
     It only modifies the X rotation performing a horizontal rotational skew.
     @see skewX, skewY */
    public var rotationalSkewX: Angle = 0° {
        didSet {
            isTransformDirty = true
        }
    }
    /** The rotation (angle) of the node in degrees. 0 is the default rotation angle. Positive values rotate node clockwise.
     It only modifies the Y rotation performing a vertical rotational skew. */
    public var rotationalSkewY: Angle = 0° {
        didSet {
            isTransformDirty = true
        }
    }
    /** The X skew angle of the node in degrees.
     This angle describes the shear distortion in the X direction.
     Thus, it is the angle between the Y axis and the left edge of the shape
     The default skewX angle is 0, with valid ranges from -90 to 90. Positive values distort the node in a clockwise direction.
     @see skewY, rotationalSkewX */
    public var skewX: Angle = 0° {
        didSet {
            isTransformDirty = true
        }
    }
    /** The Y skew angle of the node in degrees.
     This angle describes the shear distortion in the Y direction.
     Thus, it is the angle between the X axis and the bottom edge of the shape
     The default skewY angle is 0, with valid ranges from -90 to 90. Positive values distort the node in a counter-clockwise direction.
     @see skewX, rotationalSkewY */
    public var skewY: Angle = 0° {
        didSet {
            isTransformDirty = true
        }
    }
    
    // MARK: Scale
    
    /// @name Scale
    
    /** The scale factor of the node. 1.0 is the default scale factor (original size). Meaning depends on scaleType.
     It modifies the X and Y scale at the same time, preserving the node's aspect ratio.
     
     Scale is affected by the parent node's scale, ie if parent's scale is 0.5 then setting the child's scale to 2.0 will make the
     child node appear at its original size.
     @see scaleInPoints
     @see scaleType
     @see scaleX, scaleY */
    public var scale: Float {
        get {
            assert(scaleX == scaleY, "Node#scale. ScaleX != ScaleY. Don't know which one to return")
            return scaleX
        }
        set {
            scaleX = newValue
            scaleY = newValue
        }
    }
    /** The scale factor of the node. 1.0 is the default scale factor. It only modifies the X scale factor.
     
     Scale is affected by the parent node's scale, ie if parent's scale is 0.5 then setting the child's scale to 2.0 will make the
     child node appear at its original size.
     @see scaleY
     @see scaleXInPoints
     @see scale */
    public var scaleX: Float = 1.0 {
        didSet {
            isTransformDirty = true
        }
    }
    /** The scale factor of the node. 1.0 is the default scale factor. It only modifies the Y scale factor.
     
     Scale is affected by the parent node's scale, ie if parent's scale is 0.5 then setting the child's scale to 2.0 will make the
     child node appear at its original size.
     @see scaleX
     @see scaleYInPoints
     @see scale */
    public var scaleY: Float = 1.0 {
        didSet {
            isTransformDirty = true
        }
    }
    /** The scaleInPoints is the scale factor of the node in both X and Y, measured in points.
     The scaleType property indicates if the scaleInPoints will be scaled by the UIScaleFactor or not.
     See "Coordinate System and Positioning" in class overview for more information.
     
     Scale is affected by the parent node's scale, ie if parent's scale is 0.5 then setting the child's scale to 2.0 will make the
     child node appear at its original size.
     
     @see scale
     @see scaleType */
    public var scaleInPoints: Float {
        if scaleType == .scaled {
            return scale * Setup.shared.UIScale
        }
        return scale
    }
    /** The scaleInPoints is the scale factor of the node in X, measured in points.
     
     Scale is affected by the parent node's scale, ie if parent's scale is 0.5 then setting the child's scale to 2.0 will make the
     child node appear at its original size.
     
     @see scaleY, scaleYInPoints */
    public var scaleXInPoints: Float {
        if scaleType == .scaled {
            return scaleX * Setup.shared.UIScale
        }
        return scaleX
    }
    /** The scaleInPoints is the scale factor of the node in Y, measured in points.
     
     Scale is affected by the parent node's scale, ie if parent's scale is 0.5 then setting the child's scale to 2.0 will make the
     child node appear at its original size.
     
     @see scaleX
     @see scaleXInPoints */
    public var scaleYInPoints: Float {
        if scaleType == .scaled {
            return scaleY * Setup.shared.UIScale
        }
        return scaleY

    }
    /** The scaleType defines scale behavior for this node. ScaleTypeScaled indicates that the node will be scaled by Director.UIScaleFactor.
     This property is analagous to positionType. ScaleType affects the scaleInPoints of a Node.
     See "Coordinate System and Positioning" in class overview for more information.
     @see ScaleType
     @see scale
     @see scaleInPoints */
    public var scaleType = ScaleType.points {
        didSet {
            isTransformDirty = true
        }
    }
    
    // MARK: Size
    
    /// @name Size
    
    /** The untransformed size of the node in the unit specified by contentSizeType property.
     The contentSize remains the same regardless of whether the node is scaled or rotated.
     @see contentSizeInPoints
     @see contentSizeType */
    public var contentSize: Size = Size.zero {
        didSet {
            if oldValue != contentSize {
                contentSizeChanged()
            }
        }
    }
    /** The untransformed size of the node in Points. The contentSize remains the same regardless of whether the node is scaled or rotated.
     contentSizeInPoints will be scaled by the Director.UIScaleFactor if the contentSizeType is .uiPoints.
     @see contentSize
     @see contentSizeType */
    public var contentSizeInPoints: Size {
        get {
            return convertContentSizeToPoints(contentSize, type: contentSizeType)
        }
        set {
            contentSize = convertContentSizeFromPoints(newValue, type: contentSizeType)
        }
    }
    /** Defines the contentSize type used for the width and height components of the contentSize property.
     
     @see SizeType, SizeUnit
     @see contentSize
     @see contentSizeInPoints */
    public var contentSizeType = SizeType.points {
        didSet {
            contentSizeChanged()
        }
    }
    
    /** Returns an axis aligned bounding box in points, in the parent node's coordinate system.
     @see contentSize
     @see nodeToParentTransform */
    public var boundingBox: Rect {
        let rect = Rect(origin: p2d.zero, size: contentSizeInPoints)

        return rect.applying(matrix: nodeToParentMatrix)
    }
    
    // MARK: Content's anchor
    
    /// @name Content Anchor
    
    /** The anchorPoint is the point around which all transformations (scale, rotate) and positioning manipulations take place.
     The anchorPoint is normalized, like a percentage. (0,0) refers to the bottom-left corner and (1,1) refers to the top-right corner.
     The default anchorPoint is (0,0). It starts in the bottom-left corner. Sprite and some other node subclasses may have a different
     default anchorPoint, typically centered on the node (0.5,0.5).
     @warning The anchorPoint is not a replacement for moving a node. It defines how the node's content is drawn relative to the node's position.
     @see anchorPointInPoints */
    public var anchorPoint = Point.zero {
        didSet {
            if oldValue != anchorPoint {
                let contentSizeInPoints = self.contentSizeInPoints
                anchorPointInPoints = p2d(contentSizeInPoints.width * anchorPoint.x, contentSizeInPoints.height * anchorPoint.y)
                isTransformDirty = true
            }
        }
    }
    /** The anchorPoint in absolute points.
     It is calculated as follows: `x = contentSizeInPoints.width * anchorPoint.x; y = contentSizeInPoints.height * anchorPoint.y;`
     @note The returned point is relative to the node's contentSize origin, not relative to the node's position.
     @see anchorPoint */
    private(set) public var anchorPointInPoints = Point.zero
    
    // MARK: Visibility and Draw Order
    
    /// @name Visibility and Draw Order
    
    /** Whether the node and its children are visible. Default is YES.
     
     @note The children nodes will not change their visible property. Nevertheless they won't be drawn if their parent's visible property is NO.
     This means even if a node's visible property may be YES it could still be invisible if one of its parents has visible set to NO.
     
     @note Nodes that are not visible will not be rendered. For recurring use of the same nodes it is typically more
     efficient to temporarily set `node.visible = NO` compared to removeFromParent and a subsequent add(child:. */
    public var visible: Bool = true {
        willSet {
            if newValue != visible {
                director?.responderManager.markAsDirty()
            }
        }
    }
    /** The draw order of the node relative to its sibling (having the same parent) nodes. The default is 0.
     
     A zOrder of less than 0 will draw nodes behind their parent, a zOrder of 0 or greater will make the nodes draw in front
     of their parent.
     
     A parent nodes with a lower zOrder value will have itself and its children drawn behind another parent node with a higher zOrder value.
     The zOrder property only affects sibling nodes and their parent, it can not be used to change the draw order of nodes with different
     parents - in that case adjust the parent node's zOrder.
     
     @note Any sibling nodes with the same zOrder will be drawn in the order they were added as children. It is slightly more efficient
     (and certainly less confusing) to make this natural order work to your advantage.
     */
    public var zOrder: Int = 0 {
        didSet {
            if zOrder != oldValue {
                parent?.isReorderChildDirty = true
            }
        }
    }
    
    // True to ensure reorder.
    internal var isReorderChildDirty = true
    
    /// @name Color
    
    /** Sets and returns the node's color. Alpha is ignored. Changing color has no effect on non-visible nodes (ie Node, Scene).
     
     @note By default color is not "inherited" by child nodes. This can be enabled via cascadeColorEnabled.
     @see Color
     @see colorRGBA
     @see opacity
     @see cascadeColorEnabled
     */
    public var color: Color {
        get {
            return _color
        }
        set {
            //retain old alpha
            let oldAlpha = _color.a
            _displayedColor = newValue
            _color = _displayedColor
            
            _color.a = oldAlpha
            _displayedColor.a = oldAlpha
            cascadeColorIfNeeded()
        }
    }
    private var _color = Color.white
    /** Sets and returns the node's color including alpha. Changing color has no effect on non-visible nodes (ie Node, Scene).
     
     @note By default color is not "inherited" by child nodes. This can be enabled via cascadeColorEnabled.
     @see Color
     @see color
     @see opacity
     @see cascadeColorEnabled
     */
    public var colorRGBA: Color {
        get {
            return _color
        }
        set {
            _color = newValue
            _displayedColor = _color
            
            cascadeColorIfNeeded()
            cascadeOpacityIfNeeded()
        }
    }
    /** Returns the actual color used by the node. This may be different from the color and colorRGBA properties if the parent
     node has cascadeColorEnabled.
     
     @see Color
     @see color
     @see colorRGBA
     */
    public var displayedColor: Color {
        return _displayedColor
    }
    private var _displayedColor = Color.white
    /**
     CascadeColorEnabled causes changes to this node's color to cascade down to it's children. The new color is multiplied
     in with the color of each child, so it doesn't bash the current color of those nodes. Opacity is unaffected by this
     property, see cascadeOpacityEnabled to change the alpha of nodes.
     @see color
     @see colorRGBA
     @see displayedColor
     @see opacity
     */
    public var cascadeColorEnabled: Bool = false
    
    private func cascadeColorIfNeeded() {
        if cascadeColorEnabled {
            var parentColor = Color.white
            if let parent = self.parent {
                if parent.cascadeColorEnabled {
                    parentColor = parent.displayedColor
                }
            }
            self.updateDisplayedColor(parentColor)
        }
    }
    // purposefully undocumented: internal method users needn't know about
    /*
     *  Recursive method that updates display color.
     *
     *  @param color Color used for update.
     */
    
    func updateDisplayedColor(_ parentColor: Color) {
        _displayedColor.r = _color.r * parentColor.r
        _displayedColor.g = _color.g * parentColor.g
        _displayedColor.b = _color.b * parentColor.b
        // if (_cascadeColorEnabled) {
        for item: Node in children {
            item.updateDisplayedColor(_displayedColor)
        }
        // }
        // }
    }
    
    // MARK: Opacity
    
    /// @name Opacity (Alpha)
    
    /**
     Sets and returns the opacity in the range 0.0 (fully transparent) to 1.0 (fully opaque).
     
     @note By default opacity is not "inherited" by child nodes. This can be enabled via cascadeOpacityEnabled.
     @warning If the the texture has premultiplied alpha then the RGB channels will be modified.
     */
    public var opacity: Float {
        get {
          return _color.a
        }
        set {
            _color.a = newValue
            _displayedColor.a = newValue
            cascadeOpacityIfNeeded()
        }
    }
    /** Returns the actual opacity, in the range 0.0 to 1.0. This may be different from the opacity property if the parent
     node has cascadeOpacityEnabled.
     @see opacity */
    public var displayedOpacity: Float {
        return _displayedColor.a
    }
    
    /**
     CascadeOpacity causes changes to this node's opacity to cascade down to it's children. The new opacity is multiplied
     in with the opacity of each child, so it doesn't bash the current opacity of those nodes. Color is unaffected by this
     property. See cascadeColorEnabled for color changes.
     @see opacity
     @see displayedOpacity
     */
    public var cascadeOpacityEnabled: Bool = false
    
    func cascadeOpacityIfNeeded() {
        if cascadeOpacityEnabled {
            var parentOpacity: Float = 1.0
            if let parent = self.parent {
                if parent.cascadeOpacityEnabled {
                    parentOpacity = parent.displayedOpacity
                }
            }
            self.updateDisplayedOpacity(parentOpacity)
        }
    }
    // purposefully undocumented: internal method users needn't know about
    /*
     *  Recursive method that updates the displayed opacity.
     *
     *  @param opacity Opacity to use for update.
     */
    
    func updateDisplayedOpacity(_ parentOpacity: Float) {
        _displayedColor.a = _color.a * parentOpacity
        // if (_cascadeOpacityEnabled) {
        for item: Node in children {
            item.updateDisplayedOpacity(_displayedColor.a)
        }
    }
    
    // MARK: Names:
    
    /// @name Naming Nodes
    
    /** A name tag used to help identify the node easily. Can be used both to encode custom data but primarily meant
     to obtain a node by its name.
     
     @see getChildByName:recursively:
     @see userObject */
    public var name = ""
    
    // MARK: Actions
    
    /// @name Working with Actions
    
    /** If paused is set to YES, all of the node's actions and its scheduled selectors/blocks will be paused until the node is unpaused.
     
     Changing the paused state of a node will also change the paused state of its children recursively.
     
     @warning Any non-Fiber2D scheduling methods will be unaffected by the paused state. It is strongly discouraged to use NSTimer or Grand Central Disptach (GCD) `dispatch_xxx` methods to time/schedule tasks in Fiber2D.
     */
    public var paused: Bool {
        get {
            return _paused
        }
        set {
            if newValue != paused {
                let wasRun = self.active
                _paused = newValue
                wasRunning(wasRun)
                
                recursivelyIncrementPausedAncestors(paused ? 1 : -1)
            }
        }
    }
    private var _paused = false
    // Number of paused parent or ancestor nodes.
    internal var pausedAncestors = 0 {
        didSet {
            assert(pausedAncestors >= 0, "Cant be less the zero")
        }
    }
    /** Returns YES if the node is added to an active scene and neither it nor any of it's ancestors is paused. */
    public var active: Bool {
        return self.isInActiveScene && !paused && pausedAncestors == 0
    }
    
    // Components and actions that are scheduled to run on this node when onEnter is called
    internal var queuedActions    = [ActionContainer]()
    internal var queuedComponents = [Component]()
    
    // MARK: Traverse + Rendering
    /** Returns the matrix that transform the node's (local) space coordinates into the parent's space coordinates.
     The matrix is in points.
     @see parentToNodeMatrix
     */
    // should really be in +Transform but is being overriden in Camera
    public var nodeToParentMatrix: Matrix4x4f {
        calculateTransformIfNeeded()
        
        return transform
    }
    
    
    /// @name Rendering (Implemented in Subclasses)
    
    /**
     Override this method to add custom rendering code to your node.
     
     @note You should only use Fiber2D's Renderer API to modify the render state and shaders. For further info, please see the Renderer documentation.
     @warning You **must not** call `super.draw(:transform:)`
     
     @param renderer The Renderer instance to use for drawing.
     @param transform The parent node's transform.
     @see Renderer
     */
    func draw(_ renderer: Renderer, transform: Matrix4x4f) {}
    
    // purposefully undocumented: internal method, users should prefer to implement draw:transform:
    /* Recursive method that visit its children and draw them.
     * @param renderer The Renderer instance to use for drawing.
     * @param parentTransform The parent node's transform.
     */
    internal func visit(_ renderer: Renderer, parentTransform: Matrix4x4f) {
        // quick return if not visible. children won't be drawn.
        if !visible {
            return
        }
        self.sortAllChildren()
        let transform = parentTransform * nodeToParentMatrix
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
    
    //
    // MARK: Input
    //
    /** Returns YES, if touch is inside sprite
     Added hit area expansion / contraction
     Override for alternative clipping behavior, such as if you want to clip input to a circle.
     */
    override func hitTestWithWorldPos(_ pos: Point) -> Bool {
        let p = self.convertToNodeSpace(pos)
        let h = -hitAreaExpansion
        let offset = Point(-h, -h)
        // optimization
        let contentSizeInPoints = self.contentSizeInPoints
        let size: Size = Size(width: contentSizeInPoints.width - offset.x, height: contentSizeInPoints.height - offset.y)
        return !(p.y < offset.y || p.y > size.height || p.x < offset.x || p.x > size.width)
    }
    
    override func clippedHitTestWithWorldPos(_ pos: Point) -> Bool {
        // If *any* parent node clips input and we're outside their clipping range, reject the hit.
        guard parent == nil || !parent!.rejectClippedInput(pos) else {
            return false
        }
        
        return self.hitTestWithWorldPos(pos)
    }
    
    func rejectClippedInput(_ pos: Point) -> Bool {
        // If this clips input, do the bounds test to clip against this node
        if self.clipsInput && !self.hitTestWithWorldPos(pos) {
            // outside of this node, reject this!
            return true
        }
        guard let parent = self.parent else {
            // Terminating condition, the hit was not rejected
            return false
        }
        return parent.rejectClippedInput(pos)
    }
    
    //
    // MARK: Power user functionality 
    //
    
    /* The real openGL Z vertex.
     Differences between openGL Z vertex and Fiber2D Z order:
     - OpenGL Z modifies the Z vertex, and not the Z order in the relation between parent-children
     - OpenGL Z might require to set 2D projection
     - Fiber2D Z order works OK if all the nodes uses the same openGL Z vertex. eg: vertexZ = 0
     @warning: Use it at your own risk since it might break the Fiber2D parent-children z order
     */
    var vertexZ: Float = 0.0

    /* Event that is called when the running node is no longer running (eg: its Scene is being removed from the "stage" ).
     On cleanup you should break any possible circular references.
     Node's cleanup removes any possible scheduled timer and/or any possible action.
     If you override cleanup, you shall call super.cleanup()
     */
    func cleanup() {
        // Clean up timers and actions.
        stopAllActions()
        scheduler?.unschedule(target: self)
        children.forEach { $0.cleanup() }
    }
    
    // MARK: Subclasses
    open func childWasAdded(child: Node) { }
    open func childWasRemoved(child: Node) { }
    open func onExit() { }
    open func onEnter() { }
    open func onExitTransitionDidStart() { }
    open func onEnterTransitionDidFinish() { }
    
    open func contentSizeChanged() {
        // Update children
        let contentSizeInPoints: Size = self.contentSizeInPoints
        self.anchorPointInPoints = p2d(contentSizeInPoints.width * anchorPoint.x, contentSizeInPoints.height * anchorPoint.y)
        self.isTransformDirty = true
        if let layout = parent as? Layout {
            layout.needsLayout()
        }
        // Update the children (if needed)
        for child in children {
            if !child.positionType.isBasicPoints {
                // This is a position type affected by content size
                child.isTransformDirty = true
            }
        }
    }
    
    /**
     * Invoked automatically when the OS view has been resized.
     *
     * This implementation simply propagates the same method to the children.
     * Subclasses may override to actually do something when the view resizes.
     * @param newViewSize The new size of the view after it has been resized.
     */
    open func viewDidResize(to newViewSize: Size) {
        children.forEach { $0.viewDidResize(to: newViewSize) }
    }
    
    /**
     In certain special situations, you may wish to designate a node's parent without adding that node to the list
     of children. In particular this can be useful when a node references another node in an atypical non-child
     way, such as how the the ClipNode tracks the stencil. The stencil is kept outside of the normal heirarchy,
     but still needs a parent to function in a scene.
     */
    public func setRawParent(_ parent: Node) {
        _parent = parent
    }
    
    /**
     You probably want "active" instead, but this tells you if the node is in the active scene wihtout regards to its pause state.
     */
    internal(set) public var isInActiveScene: Bool = false
    
    // For Scheduler target
    internal(set) public var priority: Int = 0
}
