//
//  Input.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 08.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

public struct Input {
    public var screenPosition: Point

    #if os(OSX) || os(Linux) || os(Windows)
    public var mouseButton: MouseButton
    #endif

    #if os(iOS) || os(Android)
    public var force: Float = 1.0
    #endif
}

public extension Input {
    public func location(in node: Node) -> Point {
        return node.convertToNodeSpace(screenPosition)
    }
}

public enum MouseButton {
    // Indicates that none button is currently pressed on a mouse
    case none
    case left
    case right
    case other
}

public enum Key {

}
