//
//  UITouch+Node.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 17.10.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

#if os(iOS) || os(tvOS)
    
import UIKit
    
public extension UITouch {
    
    public func location(in node: Node) -> Point {
        let dir = Director.current
        
        let touchLocation = self.location(in: view)
        let glPoint = dir.convertToGL(Point(touchLocation))
        return node.convertToNodeSpace(glPoint)
        
    }
    
    public var locationInWorld: Point {
        let dir = Director.current
        let touchLocation = self.location(in: view)
        return dir.convertToGL(Point(touchLocation))
    }
    
}
#endif
