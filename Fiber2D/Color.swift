//
//  Color.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import simd

typealias Color = Vector4f

extension Color {
    init(white: Float, alpha: Float) {
        self.init(float4: float4(white, white, white, alpha))
    }
    
    /** Hue in degrees
     HSV-RGB Conversion adapted from code by Mr. Evil, beyondunreal wiki
     */
    init(hue: Float, saturation: Float, brightness: Float, alpha: Float) {
        let chroma: Float = saturation * brightness
        let hueSection: Float = hue / 60.0
        let X: Float = chroma * (1.0 - abs(fmod(hueSection, 2.0) - 1.0))
        var rgb = float4()
        if hueSection < 1.0 {
            rgb.x = chroma
            rgb.y = X
        }
        else if hueSection < 2.0 {
            rgb.x = X
            rgb.y = chroma
        }
        else if hueSection < 3.0 {
            rgb.y = chroma
            rgb.z = X
        }
        else if hueSection < 4.0 {
            rgb.y = X
            rgb.z = chroma
        }
        else if hueSection < 5.0 {
            rgb.x = X
            rgb.z = chroma
        }
        else if hueSection <= 6.0 {
            rgb.x = chroma
            rgb.z = X
        }
        
        let Min: Float = brightness - chroma
        rgb.x += Min
        rgb.x += Min
        rgb.z += Min
        rgb.w = alpha
        
        d = rgb
    }
    
    nonmutating func interpolating(to color: Color, factor: Float) -> Color {
        return Color(float4: simd.mix(d, color.d, t: factor))
    }
    
    mutating func premultiplyAlpha() {
        r *= a
        g *= a
        a *= a
    }
    
    nonmutating func premultiplyingAlpha() -> Color {
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
    
    static let blue      = Color(float4: float4(0.0, 0.0, 1.0, 1.0))
    static let red       = Color(float4: float4(1.0, 0.0, 0.0, 1.0))
    static let green     = Color(float4: float4(0.0, 1.0, 0.0, 1.0))
    
    static let black     = Color(float4: float4(0, 0, 0, 1))
    static let cyan      = Color(float4: float4(0, 1, 1 , 1))
    static let yellow    = Color(float4: float4(1, 1, 0 , 1))
    static let magenta   = Color(float4: float4(1, 0, 1 , 1))
    static let orange    = Color(float4: float4(1, 0.5, 0 , 1))
    static let purple    = Color(float4: float4(0.5, 0, 0.5 , 1))
    static let brown     = Color(float4: float4(0.6, 0.4, 0.2 , 1))
}

// TEMPORARY
extension Color {
    var glkVector4: GLKVector4 {
        return GLKVector4(v: (d.x, d.y, d.z, d.w))
    }
}
