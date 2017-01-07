//
//  Director+UIKit.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 03.01.17.
//
//

#if os(iOS) || os(tvOS)
import UIKit
import SwiftMath

internal extension Director {
    internal func convertTouchToGL(_ touch: UITouch) -> Point {
        let viewLocation = touch.location(in: view as? UIView)
        
        return convertToGL(Point(viewLocation))
    }
}
#endif
