//
//  Event.swift
//  Fiber2D-demo
//
//  Created by Andrey Volodin on 08.01.17.
//
//

import CSDL2

public struct EventType: Equatable {
    internal let type: SDL_EventType
    
    public init(_ type: SDL_EventType) {
        self.type = type
    }
    
    public static let audioDeviceAdded = EventType(SDL_AUDIODEVICEADDED)
    public static let audioDeviceRemoved = EventType(SDL_AUDIODEVICEREMOVED)
    public static let controllerAxisMotion = EventType(SDL_CONTROLLERAXISMOTION)
    public static let controllerButtonDown = EventType(SDL_CONTROLLERBUTTONDOWN)
    public static let controllerButtonUp = EventType(SDL_CONTROLLERBUTTONUP)
    public static let controllerDeviceAdded = EventType(SDL_CONTROLLERDEVICEADDED)
    public static let controllerDeviceRemoved = EventType(SDL_CONTROLLERDEVICEREMOVED)
    public static let controllerDeviceRemapped = EventType(SDL_CONTROLLERDEVICEREMAPPED)
    public static let dropFile = EventType(SDL_DROPFILE)
    public static let joyAxisMotion = EventType(SDL_JOYAXISMOTION)
    public static let joyBallMotion = EventType(SDL_JOYBALLMOTION)
    public static let joyHatMotion = EventType(SDL_JOYHATMOTION)
    public static let joyButtonDown = EventType(SDL_JOYBUTTONDOWN)
    public static let joyButtonUp = EventType(SDL_JOYBUTTONUP)
    public static let joyDeviceAdded = EventType(SDL_JOYDEVICEADDED)
    public static let joyDeviceRemoved = EventType(SDL_JOYDEVICEREMOVED)
    public static let keyUp = EventType(SDL_KEYUP)
    public static let keyDown = EventType(SDL_KEYDOWN)
    public static let mouseButtonDown = EventType(SDL_MOUSEBUTTONDOWN)
    public static let mouseButtonUp = EventType(SDL_MOUSEBUTTONUP)
    public static let mouseMotion = EventType(SDL_MOUSEMOTION)
    public static let mouseWheel = EventType(SDL_MOUSEWHEEL)
    public static let quit = EventType(SDL_QUIT)
    public static let sysWMEvent = EventType(SDL_SYSWMEVENT)
    public static let textEditing = EventType(SDL_TEXTEDITING)
    public static let textInput = EventType(SDL_TEXTINPUT)
    public static let userEvent = EventType(SDL_USEREVENT)
    public static let windowEvent = EventType(SDL_WINDOWEVENT)
    
    public static func ==(lhs: EventType, rhs: EventType) -> Bool {
        return lhs.type == rhs.type
    }
    
    public static func ==(lhs: EventType, rhs: SDL_EventType) -> Bool {
        return lhs.type == rhs
    }
    
    public static func ==(lhs: SDL_EventType, rhs: EventType) -> Bool {
        return lhs == rhs.type
    }
}
