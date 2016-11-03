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
    internal convenience init(pngFile: File, options: ImageOptions = .default) {
        let rescale = pngFile.autoScaleFactor * options.rescaleFactor
        
        let res: (size: Size, data: Data) = loadPNG(file: pngFile, flip: options.shouldFlipY, rgb: true, alpha: true, premultply: options.shouldPremultiply, scale: UInt(1.0 / rescale))
        
        self.init(pixelSize: res.size, contentScale: pngFile.contentScale * rescale, pixelData: res.data, options: options)
    }
}

fileprivate func loadPNG(file: File, flip: Bool, rgb: Bool, alpha: Bool, premultply pm: Bool, scale: UInt) -> (Size, Data) {
    assert(scale == 1 || scale == 2 || scale == 4, "Scale must be 1, 2 or 4.")
    
    let stream = file.openInputStream() 
    
    //	const NSUInteger PNG_SIG_BYTES = 8
    //	png_byte header[PNG_SIG_BYTES]
    //    [stream read:header maxLength:PNG_SIG_BYTES]
    //	NSCAssert(!png_sig_cmp(header, 0, PNG_SIG_BYTES), @"Bad PNG header on %@", file.name)
    
    var png = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
    if png == nil {
        fatalError("Error creating PNG read struct")
    }
    
    var png_info = png_create_info_struct(png)
    if png_info == nil {
        fatalError("libPNG error")
    }
    
    var end_info = png_create_info_struct(png)
    if end_info == nil {
        fatalError("libPNG error")
    }
    
    //assert(!setjmp(png_jmpbuf(png)), "PNG file \(file.name) could not be loaded.")
    
    //	png_init_io(png, file)
    //	png_set_sig_bytes(png, PNG_SIG_BYTES)
    //	png_read_info(png, info)
    var info = ProgressiveInfo(flip: flip,
                               rgb: rgb,
                               alpha: alpha,
                               premultiply: pm,
                               scale: png_uint_32(scale),
                               width: 0, accumulated_row: nil, accumulated_row_bytes: 0, scaled_width: 0,
                               scaled_height: 0, scaled_pixels: nil, scaled_row_bytes: 0)
    
    png_set_progressive_read_fn(png, &info, progressiveInfo, progressiveRow, nil)
    let buffer_size = 32*1024
    var buffer = [png_byte](repeating: 0, count: buffer_size)
    
    while stream.hasBytesAvailable {
        let buffered = stream.read(&buffer, maxLength: buffer_size)
        png_process_data(png, png_info, &buffer, buffered)
    }
    
    png_destroy_read_struct(&png, &png_info, &end_info)
    free(info.accumulated_row)
    stream.close()
    
    let retSize = Size(Float(info.scaled_width), Float(info.scaled_height))
    let retData = Data(bytesNoCopy: info.scaled_pixels, count: Int(info.scaled_height)*info.scaled_row_bytes, deallocator: .free)
    return (retSize, retData)
}

fileprivate func premultiply(png: png_structp?, row_info: png_row_infop?, row: png_bytep?) {
    guard let row_info = row_info,
          let row = row else {
            fatalError("Pointers can't be nil")
    }
    
    let width = Int(row_info.pointee.width)
    
    if row_info.pointee.channels == 4 {
        for i in 0..<width {
            let alpha = UInt16(row[i * 4 + 3])
            
            // Why??? UInt8(UInt16(..)..)
            // Because of precision problem, somehow Swift compiler can't handle it properly
            // So we have to first cast to UInt16, do math, then cast back
            // I don't think we can do something about it
            row[i*4 + 0] = UInt8(UInt16(row[i*4 + 0]) * alpha / 255)
            row[i*4 + 1] = UInt8(UInt16(row[i*4 + 1]) * alpha / 255)
            row[i*4 + 2] = UInt8(UInt16(row[i*4 + 2]) * alpha / 255)
        }
    } else {
        for i in 0..<width {
            let alpha: png_byte = row[i * 2 + 1]
            row[i*2 + 0] = row[i*2 + 0] * alpha / 255
        }
    }
}

fileprivate struct ProgressiveInfo {
    var flip, rgb, alpha, premultiply: Bool
    var scale: png_uint_32
    
    // Original image width
    var width: png_uint_32
    
    // Accumulation buffer used when downscaling.
    var accumulated_row: png_uint_16p!
    var accumulated_row_bytes: png_size_t
    
    // Final rescaled image.
    var scaled_width, scaled_height: png_uint_32
    var scaled_pixels: png_bytep!
    var scaled_row_bytes: png_size_t
    
    fileprivate func getScaledRowPixels(row: png_uint_32) -> png_bytep {
        var scaled_row = row / scale
        
        if !flip {
            scaled_row = scaled_height - scaled_row - 1
        }

        return scaled_pixels.advanced(by: Int(scaled_row) * scaled_row_bytes)
    }
}

fileprivate func progressiveRow(png: png_structp?, rowPixels: png_bytep?, row: png_uint_32, pass: Int32) {
    guard let png = png, let rowPixels = rowPixels else {
        fatalError("Pointrs can't be nil")
    }
    let info = png_get_progressive_ptr(png).assumingMemoryBound(to: ProgressiveInfo.self)

    let scale = Int(info.pointee.scale)
    let row_bytes = info.pointee.scaled_row_bytes
    let width = Int(info.pointee.width)

    let row_pixels = info.pointee.getScaledRowPixels(row: row)
    
    if scale == 1 {
        memcpy(row_pixels, rowPixels, row_bytes)
    } else {
        guard let accumulated = info.pointee.accumulated_row else {
            fatalError("We must have accumulated pointer")
        }
        
        for i in 0..<width {
            accumulated[(i/scale)*4 + 0] += UInt16(rowPixels[i*4 + 0])
            accumulated[(i/scale)*4 + 1] += UInt16(rowPixels[i*4 + 1])
            accumulated[(i/scale)*4 + 2] += UInt16(rowPixels[i*4 + 2])
            accumulated[(i/scale)*4 + 3] += UInt16(rowPixels[i*4 + 3])
        }
        
        let mask = info.pointee.scale - 1
        
        if row & mask == mask {
            for i in 0..<row_bytes {
                // Divde and copy the accumulated value
                row_pixels[i] = UInt8(Int(accumulated[i]) >> scale)
                // Clear the accumulated value
                accumulated[i] = 0
            }
        }
    }
}

fileprivate func progressiveInfo(png: png_structp?, png_info: png_infop?) {
        let info = png_get_progressive_ptr(png).assumingMemoryBound(to: ProgressiveInfo.self)
        
        info.pointee.width = png_get_image_width(png, png_info)
        
        let scale = info.pointee.scale
        info.pointee.scaled_width = (info.pointee.width + scale - 1)/scale
        info.pointee.scaled_height = (png_get_image_height(png, png_info) + scale - 1)/scale
    
        let bit_depth = png_get_bit_depth(png, png_info)
        let color_type = Int32(png_get_color_type(png, png_info))
        
        if color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8{
            png_set_expand_gray_1_2_4_to_8(png)
        }
        
        if (bit_depth == 16){
            png_set_strip_16(png)
        }
    
        if(info.pointee.rgb){
            if color_type == PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_PALETTE {
                png_set_palette_to_rgb(png)
            } else if(color_type == PNG_COLOR_TYPE_GRAY || color_type == PNG_COLOR_TYPE_GRAY_ALPHA){
                png_set_gray_to_rgb(png)
            }
        } else {
            assert(color_type != PNG_COLOR_TYPE_PALETTE, "Paletted PNG to grayscale conversion not supported.")
            
            if(color_type == PNG_COLOR_TYPE_RGB || color_type == PNG_COLOR_TYPE_RGB_ALPHA){
                png_set_rgb_to_gray_fixed(png, 1, -1, -1)
            }
        }
        
        if info.pointee.alpha {
            if png_get_valid(png, png_info, png_uint_32(PNG_INFO_tRNS)) != 0 {
                png_set_tRNS_to_alpha(png)
            } else {
                png_set_filler(png, 0xff, PNG_FILLER_AFTER)
            }
        } else 	{
            if color_type & PNG_COLOR_MASK_ALPHA != 0 {
                png_set_strip_alpha(png)
            }
        }
        
        if info.pointee.premultiply {
            png_set_read_user_transform_fn(png, premultiply)
        }
        
        png_read_update_info(png, png_info)
        
        let bpp = png_get_rowbytes(png, png_info) / png_size_t(info.pointee.width)
        info.pointee.accumulated_row_bytes = bpp * 2 * png_size_t(info.pointee.scaled_width)
    
        if info.pointee.scale > 1 {
            info.pointee.accumulated_row = calloc(Int(info.pointee.scaled_width), 2*bpp).assumingMemoryBound(to: UInt16.self)
        }
        
        // Rescaled image rows are tightly packed.
        info.pointee.scaled_row_bytes = bpp * png_size_t(info.pointee.scaled_width)
        info.pointee.scaled_pixels = malloc(info.pointee.scaled_row_bytes*png_size_t(info.pointee.scaled_height)).assumingMemoryBound(to: UInt8.self)
}
