//
//  Window.swift
//  Fiber2D-demo
//
//  Created by Andrey Volodin on 14.12.16.
//
//

import CSDL2
import SwiftMath

public struct WindowFlags: OptionSet {
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    static let fullscreen = WindowFlags(rawValue: SDL_WINDOW_FULLSCREEN.rawValue)
    static let openGL = WindowFlags(rawValue: SDL_WINDOW_OPENGL.rawValue)
    static let shown = WindowFlags(rawValue: SDL_WINDOW_SHOWN.rawValue)
    static let hidden = WindowFlags(rawValue: SDL_WINDOW_HIDDEN.rawValue)
    static let borderless = WindowFlags(rawValue: SDL_WINDOW_BORDERLESS.rawValue)
    static let resizable = WindowFlags(rawValue: SDL_WINDOW_RESIZABLE.rawValue)
    static let ninimised = WindowFlags(rawValue: SDL_WINDOW_MINIMIZED.rawValue)
    static let saximised = WindowFlags(rawValue: SDL_WINDOW_MAXIMIZED.rawValue)
    static let inputGrabbed = WindowFlags(rawValue: SDL_WINDOW_INPUT_GRABBED.rawValue)
    static let inputFocus = WindowFlags(rawValue: SDL_WINDOW_INPUT_FOCUS.rawValue)
    static let mouseFocus = WindowFlags(rawValue: SDL_WINDOW_MOUSE_FOCUS.rawValue)
    static let fullscreenDesktop = WindowFlags(rawValue: SDL_WINDOW_FULLSCREEN_DESKTOP.rawValue)
    static let foreign = WindowFlags(rawValue: SDL_WINDOW_FOREIGN.rawValue)
    static let allowHighDPI = WindowFlags(rawValue: SDL_WINDOW_ALLOW_HIGHDPI.rawValue)
    static let mouseCapture = WindowFlags(rawValue: SDL_WINDOW_MOUSE_CAPTURE.rawValue)
}

let WindowPosUndefined = SDL_WINDOWPOS_UNDEFINED_MASK | 0
let WindowPosCentered = SDL_WINDOWPOS_CENTERED_MASK | 0

public class Window {
    
    let theWindow: OpaquePointer
    
    public init(title: String = "Untitled", origin: Point, size: Size, flags: WindowFlags) {
        theWindow = SDL_CreateWindow(title,
                                     Int32(origin.x), Int32(origin.y),
                                     Int32(size.width), Int32(size.height),
                                     flags.rawValue)
        
    }
    
    deinit {
        SDL_DestroyWindow(theWindow)
    }
    
    public var title: String {
        get {
            return String(describing: SDL_GetWindowTitle(theWindow))
        }
        set(newTitle) {
            SDL_SetWindowTitle(theWindow, newTitle)
        }
    }
    
    public var id: UInt32 {
        return SDL_GetWindowID(theWindow)
    }
    
    public var width: Int {
        var width: Int32 = 0
        SDL_GetWindowSize(theWindow, &width, nil)
        return Int(width)
    }
    
    public var height: Int {
        var height: Int32 = 0
        SDL_GetWindowSize(theWindow, nil, &height)
        return Int(height)
    }
    
    /*public var screenKeyboardShown: Bool {
        return Keyboard.isScreenKeyboardShownOnWindow(self)
    }
    
    public var renderer: Renderer {
        if theRenderer == nil {
            theRenderer = WindowRenderer(window: self)
        }
        return theRenderer!
    }
    
    public var surface: Surface {
        if windowSurface == nil {
            windowSurface = Surface(sdlSurface: SDL_GetWindowSurface(theWindow), takeOwnership: false)
        }
        return windowSurface!
    }*/
    
    public func show() {
        SDL_ShowWindow(theWindow)
    }
    
    public func hide() {
        SDL_HideWindow(theWindow)
    }
    
    public func setWidth(width: Int, height: Int) {
        SDL_SetWindowSize(theWindow, Int32(width), Int32(height))
    }
    
    /*public func showMessageBox(type: MessageBoxType, title: String, message: String) {
        showSimpleMessageBox(type, title: title, message: message, window: self)
    }*/
    
    public func update() {
        SDL_UpdateWindowSurface(theWindow)
    }
    
    public func updateRects() {
        // TODO: implement using SDL_UpdateWindowSurfaceRects()
    }
    
    /*public func _sdlWindow() -> COpaquePointer {
        return theWindow
    }
    
    var theRenderer: WindowRenderer?
    var windowSurface: Surface?*/
}
