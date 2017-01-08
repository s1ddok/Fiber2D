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
    internal func convertUITouchToInput(_ touch: UITouch) -> Input {
        let viewLocation = touch.location(in: view as? UIView)
        
        return Input(screenPosition: convertToGL(Point(viewLocation)), force: Float(touch.force))
    }
}
#endif
