//
//  Cloneable.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 25.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public protocol Cloneable {
    /// Returns new object that is a clone of a given instance
    var clone: Self { get }
}
