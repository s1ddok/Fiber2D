//
//  Texture+Image.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 28.10.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftBGFX
import Foundation

public extension Texture {
    public static func make(from image: Image) -> Texture {
        let w = UInt16(image.sizeInPixels.width)
        let h = UInt16(image.sizeInPixels.height)
        let size = UInt32(w * h) * UInt32(MemoryLayout<Float>.size / MemoryLayout<UInt8>.size)
        let memoryBlock = MemoryBlock(size: size)
        image.pixelData?.copyBytes(to: memoryBlock.data, count: Int(size))
        
        return Texture.make2D(width: w, height: h, mipCount: 1, format: .bgra8, memory: memoryBlock)
    }
}
