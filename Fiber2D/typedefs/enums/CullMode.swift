//
//  CullMode.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 24.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftBGFX

public struct CullMode {
    internal let renderState: RenderStateOptions
    /// Don't perform culling of back faces.
    public static let none = CullMode(renderState: RenderStateOptions.noCulling)
    /// Perform culling of clockwise faces.
    public static let clockwise = CullMode(renderState: RenderStateOptions.cullClockwise)
    /// Perform culling of counter-clockwise faces.
    public static let counterClockwise = CullMode(renderState: RenderStateOptions.cullCounterclockwise)
}

