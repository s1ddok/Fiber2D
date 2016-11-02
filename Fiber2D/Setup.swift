//
//  Setup.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 02.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public class Setup {
    public static let shared = Setup()
    
    /**
     Global content scale for the app.
     This is the number of pixels on the screen that are equivalent to a point in Fiber2D.
     */
    public var contentScale: Float = 1.0
    
    /**
     Minimum content scale of assets such as textures, TTF labels or render textures.
     Normally you want this value to be the same as the contentScale, but on Mac you may want a higher value since the user could resize the window.
     */
    public var assetScale: Float = 1.0
    
    /**
     UI scaling factor. Positions and content sizes are scale by this factor if the position type is set to UIScale.
     This is useful for creating UIs that have the same physical size (ex: centimeters) on different devices.
     This also affects the loading of assets marked as having a UIScale.
     */
    public var UIScale: Float = 1.0
    
    /**
     Default fixed update interval that will be used when initializing schedulers.
     */
    public var fixedUpdateInterval: Float = 1.0 / 60.0
}
