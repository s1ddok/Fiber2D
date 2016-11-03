//
//  Extensions-Temp.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath
import CoreGraphics

#if os(iOS) || os(tvOS) || os(OSX)
    
extension Vector2f {
    var cgPoint: CGPoint {
        return CGPoint(x: Double(x), y: Double(y))
    }
    
    init(_ cgPoint: CGPoint) {
        self.init(Float(cgPoint.x), Float(cgPoint.y))
    }
}

extension Size {
    init(CGSize: CGSize) {
        self.init(Float(CGSize.width), Float(CGSize.height))
    }
    
    var cgSize: CGSize {
        return CGSize(width: CGFloat(width), height: CGFloat(height))
    }
}

extension Rect {
    init(CGRect: CGRect) {
        self.init(origin: p2d(CGRect.origin), size: Size(CGSize: CGRect.size))
    }
}
    
#endif
