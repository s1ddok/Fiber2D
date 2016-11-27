//
//  Layout.swift
//
//  Created by Andrey Volodin on 26.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

/**
 The layout node is an abstract class. It will take control of its childrens' positions.
 
 Do not create instances of Layout, instead use one of its subclasses:
 
 - LayoutBox
 
 **Note:** If you are using a layout node you should not set the positions of the layout node's children manually or via move actions.
 
 ### Subclassing Note
 
 Layout is an abstract class for nodes that provide layouts. You should subclass Layout to create your own layout node.
 Implement the layout method to create your own layout.
 */
public class Layout: Node {
    private var _needsLayout = false
    
    override init() {
        super.init()
        self.needsLayout()
        onChildWasAdded.subscribe(on: self) { _ in
            self.sortAllChildren()
            self.layout()
        }
        
        onChildWasRemoved.subscribe(on: self) {
            _ in self.needsLayout()
        }
    }
    
    /** @name Methods Implemented by Subclasses */
    
    /**
     *  Called whenever the node needs to layout its children again. Normally, there is no need to call this method directly.
     */
    public func needsLayout() {
        self._needsLayout = true
    }
    
    /**
     The layout method layouts the children according to the rules implemented in a CCLayout subclass.
     @note Your subclass must call `super.layout()` to reset the _needsLayout flag. Not calling super could cause the layout
     to unnecessarily run the layout method every frame.
     */
    public func layout() {
        self._needsLayout = false
    }
    
    override public var contentSize: Size {
        get {
            if _needsLayout {
                self.layout()
            }
            return super.contentSize
        }
        set {
            super.contentSize = newValue
        }
    }
    
    override func visit(_ renderer: Renderer, parentTransform: Matrix4x4f) {
        if _needsLayout {
            self.layout()
        }
        super.visit(renderer, parentTransform: parentTransform)
    }
}
