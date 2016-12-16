//
//  Director+Internal.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 29.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath
#if os(iOS) || os(tvOS) || os(macOS)
import Quartz
#else
import Glibc
#endif

/**
 Get the current time in seconds.
 */
internal extension Time {
    internal static var absoluteTime: Time {
        #if os(iOS) || os(tvOS) || os(OSX) || os(watchOS)
        return Time(CACurrentMediaTime())
        #else
        var t = timespec()
        clock_gettime(CLOCK_MONOTONIC, &t)

        return Time(t.tv_sec) + Time(t.tv_nsec) / Time(1.0e-9)
        #endif
    }
}

internal extension Director {
    /// Add a block to be called when the GPU finishes rendering a frame.
    /// This is used to pool rendering resources (renderers, buffers, textures, etc) without stalling the GPU pipeline.
    internal func add(frameCompletionHandler: @escaping ()->()) {
        self.view!.add(frameCompletionHandler: frameCompletionHandler)
    }

    internal func antiFlickrDrawCall() {
        // Questionable "anti-flickr", extra draw call:
        // overridden for android.
        self.mainLoopBody()
    }

    internal func calculateDeltaTime() {
        let now = Time.absoluteTime
        // new delta time
        if nextDeltaTimeZero {
            self.dt = 0
            self.nextDeltaTimeZero = false
        } else {
            self.dt = now - lastUpdate
            self.dt = max(0, dt)
        }
        // If we are debugging our code, prevent big delta time
        if dt > 0.2 {
            self.dt = 1 / 60.0
        }
        self.lastUpdate = now
    }

    internal var flipY: Float {
        #if os(iOS) || os(tvOS)
            return -1.0
        #endif
        #if os(OSX) || os(Linux) || os(Android)
            return 1.0
        #endif
    }

    /// Rect of the visible screen area in GL coordinates.
    internal var viewportRect: Rect {
        var projection = runningScene!.projection
        // TODO It's _possible_ that a user will use a non-axis aligned projection. Weird, but possible.
        let projectionInv = projection.inversed
        // Calculate z=0 using -> transform*[0, 0, 0, 1]/w
        let zClip = projection[3, 2] / projection[3, 3]
        // Bottom left and top right coords of viewport in clip coords.
        let clipBL = Vector3f(-1.0, -1.0, zClip)
        let clipTR = Vector3f(1.0, 1.0, zClip)
        // Bottom left and top right coords in GL coords.
        let glBL = projectionInv.multiplyAndProject(v: clipBL).xy
        let glTR = projectionInv.multiplyAndProject(v: clipTR).xy
        return Rect(bottomLeft: glBL, topRight: glTR)
    }
}
