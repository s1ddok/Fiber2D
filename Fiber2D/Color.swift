//
//  Color.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

public typealias Color = Vector4f

public extension Color {
    public init(white: Float, alpha: Float) {
        self.init(white, white, white, alpha)
    }
    
    /** Hue in degrees
     HSV-RGB Conversion adapted from code by Mr. Evil, beyondunreal wiki
     */
    public init(hue: Float, saturation: Float, brightness: Float, alpha: Float) {
        let chroma: Float = saturation * brightness
        let hueSection: Float = hue / 60.0
        let X: Float = chroma * (1.0 - abs(fmod(hueSection, 2.0) - 1.0))
        var r:Float = 0.0, g:Float = 0.0, b:Float = 0.0, a: Float = 0.0
        if hueSection < 1.0 {
            r = chroma
            g = X
        } else if hueSection < 2.0 {
            r = X
            g = chroma
        } else if hueSection < 3.0 {
            g = chroma
            b = X
        } else if hueSection < 4.0 {
            g = X
            b = chroma
        } else if hueSection < 5.0 {
            r = X
            b = chroma
        } else if hueSection <= 6.0 {
            r = chroma
            b = X
        }
        
        let Min: Float = brightness - chroma
        r += Min
        g += Min
        b += Min
        a = alpha
        
        self.init(r, g, b, a)
    }
    
    public mutating func premultiplyAlpha() {
        r *= a
        g *= a
        b *= a
    }
    
    public var premultiplyingAlpha: Color {
        var retVal = self
        retVal.premultiplyAlpha()
        return retVal
    }
    
    public var white: Float {
        return (r + g + b) / 3.0
    }
}

// MARK: Constants
public extension Color {
    public static let clear     = Color(0.0)
    public static let darkGray  = Color(white: 1.0/3.0, alpha: 1)
    public static let lightGray = Color(white: 2.0/3.0, alpha:1)
    public static let white     = Color(white: 1, alpha: 1)
    public static let gray      = Color(white: 0.5, alpha: 1)
    
    public static let blue      = Color(0.0, 0.0, 1.0, 1.0)
    public static let red       = Color(1.0, 0.0, 0.0, 1.0)
    public static let green     = Color(0.0, 1.0, 0.0, 1.0)
    
    public static let black     = Color(0, 0, 0, 1)
    public static let cyan      = Color(0, 1, 1 , 1)
    public static let yellow    = Color(1, 1, 0 , 1)
    public static let magenta   = Color(1, 0, 1 , 1)
    public static let orange    = Color(1, 0.5, 0 , 1)
    public static let purple    = Color(0.5, 0, 0.5 , 1)
    public static let brown     = Color(0.6, 0.4, 0.2 , 1)
}

public extension Color {
    public var uint32Representation: UInt32 {
        let r = UInt32(self.r * 255) << 24
        let g = UInt32(self.g * 255) << 16
        let b = UInt32(self.b * 255) << 8
        let a = UInt32(self.a * 255)
        
        return r | g | b | a
    }
}
