//
//  Director+Internal.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 29.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/**
 Get the current time in seconds.
 */
internal extension Time {
    internal static var absoluteTime: Time {
        #if os(iOS) || os(tvOS) || os(OSX) || os(watchOS)
            return Time(CACurrentMediaTime())
        #endif
    }
}
