//
//  Texture+Image.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.10.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftBGFX
import SwiftMath
import Foundation

public extension Texture {
    public static func make(from image: Image) -> Texture {
        let w = UInt16(image.sizeInPixels.width)
        let h = UInt16(image.sizeInPixels.height)
        let size = UInt32(w * h) * UInt32(MemoryLayout<Float>.size / MemoryLayout<UInt8>.size)
        let memoryBlock = MemoryBlock(size: size)
        image.pixelData?.copyBytes(to: memoryBlock.data, count: Int(size))
        
        let tex = Texture(bgfxTexture: BGFXTexture.make2D(width: w, height: h,
                                                       mipCount: 1, format: .bgra8,
                                                       memory: memoryBlock))
        tex.contentScale = image.contentScale
        tex.contentSizeInPixels = image.sizeInPixels
        return tex
    }
    
    // TODO: Should have more parameters
    public static func makeRenderTexture(of size: Size) -> Texture {
        let w = UInt16(size.width)
        let h = UInt16(size.height)

        let tex = BGFXTexture.make2D(width: w, height: h, mipCount: 1, format: .bgra8, options: [.renderTarget, .clampU, .clampV], memory: nil)
        
        let retVal = Texture(bgfxTexture: tex)
        retVal.contentScale = Setup.shared.assetScale
        retVal.contentSizeInPixels = size
        return retVal
    }
}
