//
//  Image+PNG.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 24.10.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import Foundation
import SwiftMath

public extension Image {
    internal convenience init(pngFile: CCFile, options: ImageOptions = .default) {
        let rescale = Float(pngFile.autoScaleFactor) * options.rescaleFactor
        
        // FIXME: Temporary
        var size = CGSize.zero
        //var size = Size.zero
        let data = LoadPNG(pngFile, options.shouldFlipY, true, true, options.shouldPremultiply, UInt(1.0 / rescale), &size)
        
        self.init(pixelSize: Size(CGSize: size), contentScale: Float(pngFile.contentScale) * rescale, pixelData: data! as Data, options: options)
    }
}
