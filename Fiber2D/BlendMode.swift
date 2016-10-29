//
//  BlendMode.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 29.10.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftBGFX

/// Blending modes used with certain node's `blendMode` property. BlendMode treats blend modes by descriptive name rather
/// than a nondescriptive combination of blend mode identifiers.
public struct BlendMode {
    internal var state: RenderStateOptions
    internal var equation: RenderStateOptions
    
    /// @name Getting a Built-In Blend Mode
    
    /// Disabled blending mode. Use this with fully opaque surfaces for extra performance.
    public static let disabledMode = BlendMode(state: .blend(source:      .blendOne,
                                                             destination: .blendZero),
                                               equation: .blendEquationAdd)
    /// Pre-multiplied alpha blending. (This is usually the default)
    public static let premultipliedAlphaMode = BlendMode(state: .blend(source:      .blendSourceAlpha,
                                                                       destination: .blendInverseSourceAlpha),
                                                         equation: .blendEquationAdd)
    
    /// Additive blending. (Similar to PhotoShop's linear dodge mode)
    public static let addMode = BlendMode(state: .blend(source:      .blendOne,
                                                        destination: .blendOne),
                                          equation: .blendEquationAdd)
    /// Regular alpha blending.
    public static let alphaMode = BlendMode(state: .blend(source:      .blendOne,
                                                          destination: .blendInverseSourceAlpha),
                                            equation: .blendEquationAdd)

    /// Multiply blending mode. (Similar to PhotoShop's burn mode)
    public static let multiplyMode = BlendMode(state: .blend(source:      .blendDestinationColor,
                                                             destination: .blendZero),
                                               equation: .blendEquationAdd)
}

extension BlendMode: Equatable {
    public static func ==(lhs: BlendMode, rhs: BlendMode) -> Bool {
        return lhs.state == rhs.state && lhs.equation == rhs.equation
    }
}
