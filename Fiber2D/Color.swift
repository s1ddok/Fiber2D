//
//  Color.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

typealias Color = Vector4f

extension Color {
    init(white: Float, alpha: Float) {
        self.init(white, white, white, alpha)
    }
    
    /** Hue in degrees
     HSV-RGB Conversion adapted from code by Mr. Evil, beyondunreal wiki
     */
    init(hue: Float, saturation: Float, brightness: Float, alpha: Float) {
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
    
    mutating func premultiplyAlpha() {
        r *= a
        g *= a
        a *= a
    }
    
    var premultiplyingAlpha: Color {
        var retVal = self
        retVal.premultiplyAlpha()
        return retVal
    }
    
    var white: Float {
        return (r + g + b) / 3.0
    }
}

// MARK: Constants
extension Color {
    static let clear     = Color(0.0)
    static let darkGray  = Color(white: 1.0/3.0, alpha: 1)
    static let lightGray = Color(white: 2.0/3.0, alpha:1)
    static let white     = Color(white: 1, alpha: 1)
    static let gray      = Color(white: 0.5, alpha: 1)
    
    static let blue      = Color(0.0, 0.0, 1.0, 1.0)
    static let red       = Color(1.0, 0.0, 0.0, 1.0)
    static let green     = Color(0.0, 1.0, 0.0, 1.0)
    
    static let black     = Color(0, 0, 0, 1)
    static let cyan      = Color(0, 1, 1 , 1)
    static let yellow    = Color(1, 1, 0 , 1)
    static let magenta   = Color(1, 0, 1 , 1)
    static let orange    = Color(1, 0.5, 0 , 1)
    static let purple    = Color(0.5, 0, 0.5 , 1)
    static let brown     = Color(0.6, 0.4, 0.2 , 1)
}
