//
//  ResponderManager+SDL.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 16.12.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

#if os(Linux) || os(Android)

internal extension ResponderManager {
    internal func cancel(responder: RunningResponder) {
        runningResponderList.removeObject(responder)
    }
}

#endif
