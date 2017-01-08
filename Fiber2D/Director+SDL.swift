//
//  Director+SDL.swift
//  Fiber2D-iOS
//
//  Created by Andrey Volodin on 08.01.17.
//
//

#if os(Android)
import CSDL2
import SwiftMath

internal extension Director {
    func convertSDLTouchEventToInput(_ event: SDL_TouchFingerEvent) -> Input {
        let normalizedPosition = p2d(event.x, event.y)
        let positionInPoints = normalizedPosition * viewSize
        
        return Input(screenPosition: positionInPoints, force: event.pressure)
    }
}

#endif
