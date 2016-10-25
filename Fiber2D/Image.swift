//
//  Image.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 24.10.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import Foundation
import SwiftMath

public struct ImageOptions {
     /**
     How much to rescale the image while loading it.
     
     The default value is 1.0.
     
     @warning Some image loaders may only support inverse powers of two (1/2, 1/4, etc)
     */
    public var rescaleFactor: Float = 1.0
     
     /**
     Should the image dimensions be expanded to a power of two while loading?
     
     The default value is `false`.
     */
    public var shouldExpandToPOT: Bool = false
     
     /**
     Should the image alpha be premultiplied while loading?
     
     The default value is `true`.
     
     @warning Some image loaders only support pre-multiplied alpha.
     */
    public var shouldPremultiply: Bool = true
    
    public var shouldFlipX = false
    public var shouldFlipY = false
    
    public static let `default` = ImageOptions()
}


@objc public final class Image: NSObject {
    
    @objc public convenience init(file: CCFile) {
        self.init(file: file, options: .default)
    }
    /**
     Initialize a new image with raw pixel data. All default options are applied to the image.
     
     @param pixelSize    Size of the image in pixels.
     @param contentScale Content scale of the image.
     @param pixelData    A pointer to raw, tightly packed, RGBA8 pixel data.
     @param options Optional parameter of type ImageOptions.
     
     @return An image object that wraps the given pixel data.
     */
    public init(pixelSize: Size, contentScale: Float, pixelData: Data?, options: ImageOptions = .default) {
        
        self.contentScale = contentScale
        self.contentSize  = pixelSize * (1.0 / contentScale)
        
        self.options   = options
        self.pixelData = pixelData
        
        super.init()
        self.sizeInPixels.width  = floor(pixelSize.width)
        self.sizeInPixels.height = floor(pixelSize.height)
        
    }
    
    /**
     @param file    The CCFile to load the image data from.
     @param options Optional parameter of type ImageOptions.
     
     @return An image loaded from the file.
     */
    public convenience init(file: CCFile, options: ImageOptions = .default) {
        //if file.name.hasSuffix(".png") {
            // use libpng
        //} else {
            // use other loader (i.e. CoreGraphics)
        //}
        
        // FIXME: Only works for .png for now
        self.init(pngFile: file, options: options)
    }
    
    /**
     Size of the image's bitmap in pixels.
     */
    @nonobjc
    internal(set) public var sizeInPixels = Size.zero
    
    @objc(sizeInPixels)
    public var objc_sizeInPixels: CGSize {
        return sizeInPixels.cgSize
    }
    
    /**
     Bitmap data pointer. The format will always be RGBA8.
     */
    internal(set) public var pixelData: Data?
    
    /**
     Content scale of the bitmap
     */
    internal(set) public var contentScale: Float
    
    /**
     User assignable content size of the image in points.
     
     This value may not equal pixelSize/contentScale if the image is padded.
     It defaults to the original size of the image in points.
     */
    @nonobjc
    public var contentSize: Size
    
    @objc(contentSize)
    public var objc_contentSize: CGSize {
        return contentSize.cgSize
    }
    
    internal var options: ImageOptions
    
}
