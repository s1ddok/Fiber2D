//
//  FreeTypeFont.swift
//  Fiber2D-macOS
//
//  Created by Andrey Volodin on 30.01.17.
//
//

import CFreeType
import Cedtaa3
import SwiftMath
import Foundation

public class FreeTypeFont: Font {
    
    // MARK: Font conformance
    
    public var maxHeight: Int { return 0 }
    
    public var fontAtlas: FontAtlas {
        if _fontAtlas == nil {
            _fontAtlas = FontAtlas(font: self)
            
            switch glyphCollection {
            case .dynamic: ()
            default:
                if let fa = _fontAtlas, let gs = self.glyphCollection.glyphString {
                    fa.prepareLetterDefinitions(for: String(describing: gs.utf16))
                }
            }
        }
        
        return _fontAtlas!
    }
    
    internal var _fontAtlas: FontAtlas?
    
    public func horizontalKernings(for text: String) -> [Int]! {
        guard fontRef != nil else { return nil }
        guard text.characters.count > 0 else { return nil }
        
        var sizes = [Int](repeating: 0, count: text.characters.count)
        
        if (fontRef.pointee.face_flags & FT_FACE_FLAG_KERNING) != 0 {
            for c in 1..<text.characters.count {
                let firstChar  = text[text.index(text.startIndex, offsetBy: c-1)]
                let secondChar = text[text.index(text.startIndex, offsetBy: c)]
                sizes[c] = horizontalKernings(firstChar: firstChar.unicodeScalarCodePoint,
                                              secondChar: secondChar.unicodeScalarCodePoint)
            }
            
        }
        return sizes
    }

    // MARK: Init
    
    public init(outlineSize: Float = 0) {
        self.outlineSize = outlineSize
        if outlineSize > 0.0 {
            self.outlineSize *= Setup.shared.contentScale
            FT_Stroker_New(FreeTypeFont.library, &stroker)
            FT_Stroker_Set(stroker!, Int(outlineSize * 64.0), FT_STROKER_LINECAP_ROUND, FT_STROKER_LINEJOIN_ROUND, 0)
        }
    }
    
    deinit {
        if FreeTypeFont.freeTypeInitialized {
            if let stroker = self.stroker {
                FT_Stroker_Done(stroker)
            }
            
            if let fontRef = self.fontRef {
                FT_Done_Face(fontRef)
            }
        }
    }
    
    // MARK: Properties
    
    public var name: String = ""
    public var fontFamiliy: String {
        return String(cString: fontRef.pointee.family_name)
    }
    public var fontAscender: Int {
        return Int(fontRef.pointee.size.pointee.metrics.ascender >> 6)
    }
    public var fontRef: FT_Face!
    public var lineHeight: Int = 0
    
    public var isDistanceFieldEnabled: Bool = false
    
    public var encoding = FT_ENCODING_UNICODE

    internal static var cacheFontData = [String: Data]()
    
    internal static func shutDownFreeType() {
        if freeTypeInitialized {
            FT_Done_FreeType(library)
            FreeTypeFont.cacheFontData.removeAll()
            freeTypeInitialized = false
        }
    }
    
    public func renderChar(at dest: inout [UInt8], posX: Int, posY: Int, bitmap: [UInt8], bitmapWidth: Int, bitmapHeight: Int) {
        var iX = posX
        var iY = posY
        
        if isDistanceFieldEnabled {
            let distanceMap = self.distanceMap(image: bitmap, width: bitmapWidth, height: bitmapHeight)
            
            let bitmapWidth  = bitmapWidth  + 2 * FreeTypeFont.distanceMapSpread
            let bitmapHeight = bitmapHeight + 2 * FreeTypeFont.distanceMapSpread
            
            for y in 0..<bitmapHeight {
                let bitmap_y = y * bitmapWidth
                
                for x in 0..<bitmapWidth {
                    //Single channel 8-bit output
                    dest[iX + iY * FontAtlas.cacheTextureWidth] = distanceMap[bitmap_y + x]
                    
                    iX += 1
                }
                
                iX = posX
                iY += 1
            }
        } else if outlineSize > 0 {
            var tempChar: UInt8 = 0
            for y in 0..<bitmapHeight {
                let bitmap_y = y * bitmapWidth
                
                for x in 0..<bitmapWidth {
                    tempChar = bitmap[(bitmap_y + x) * 2]
                    dest[(iX + (iY * FontAtlas.cacheTextureWidth)) * 2] = tempChar
                    tempChar = bitmap[(bitmap_y + x) * 2 + 1]
                    dest[(iX + (iY * FontAtlas.cacheTextureWidth)) * 2 + 1] = tempChar
                    
                    iX += 1
                }
                
                iX = posX
                iY += 1
            }
        } else {
            for y in 0..<bitmapHeight {
                let bitmap_y = y * bitmapWidth
                
                for x in 0..<bitmapWidth {
                    let cTemp = bitmap[bitmap_y + x]
                    
                    // the final pixel
                    dest[iX + iY * FontAtlas.cacheTextureWidth] = cTemp
                    
                    iX += 1
                }
                
                iX = posX
                iY += 1
            }
        }
    }
    
    public func glyphBitmap(for theChar: UInt) -> (buffer: UnsafeMutablePointer<UInt8>,
                                                   width: UInt,
                                                   height: UInt,
                                                   rect: Rect,
                                                   xAdvance: Int)? {
        guard let fontRef = fontRef else { return nil }
        
        if isDistanceFieldEnabled {
            if FT_Load_Char(fontRef, theChar, Int32(FT_LOAD_RENDER) | Int32(FT_LOAD_NO_HINTING) | Int32(FT_LOAD_NO_AUTOHINT)) != 0 {
                return nil
            }
        } else {
            if FT_Load_Char(fontRef, theChar, Int32(FT_LOAD_RENDER) | Int32(FT_LOAD_NO_AUTOHINT)) != 0 {
                return nil
            }
        }

        let metrics = fontRef.pointee.glyph.pointee.metrics
        var outRect = Rect(origin: Point(metrics.horiBearingX >> 6, -(metrics.horiBearingY >> 6)), size: Size(metrics.width >> 6, metrics.height >> 6))
        
        var xAdvance = Int(fontRef.pointee.glyph.pointee.metrics.horiAdvance >> 6)
        
        var outWidth  = UInt(fontRef.pointee.glyph.pointee.bitmap.width)
        var outHeight = UInt(fontRef.pointee.glyph.pointee.bitmap.rows)
        var ret = fontRef.pointee.glyph.pointee.bitmap.buffer
        
        guard outlineSize > 0 && outWidth > 0 && outHeight > 0 else {
            return (buffer: ret!, width: outWidth, height: outHeight, rect: outRect, xAdvance: xAdvance)
        }
        
        let copyBitmapSize = Int(outWidth * outHeight)
        let copyBitmap = UnsafeMutablePointer<UInt8>.allocate(capacity: copyBitmapSize)
        memcpy(copyBitmap, ret, copyBitmapSize * MemoryLayout<UInt8>.size)
        
        var bbox = FT_BBox()
        guard let outlineBitmap = glyphBitmapWithOutline(for: theChar, bbox: &bbox) else {
            free(copyBitmap)
            return nil
        }
        
        let glyphMinX = Int32(outRect.origin.x)
        let glyphMaxX = Int32(outRect.origin.x) + Int32(outWidth)
        let glyphMinY = -Int32(outHeight) - Int32(outRect.origin.y)
        let glyphMaxY = -Int32(outRect.origin.y)
        
        let outlineMinX = Int32(bbox.xMin >> 6)
        let outlineMaxX = Int32(bbox.xMax >> 6)
        let outlineMinY = Int32(bbox.yMin >> 6)
        let outlineMaxY = Int32(bbox.yMax >> 6)
        let outlineWidth = outlineMaxX - outlineMinX
        let outlineHeight = outlineMaxY - outlineMinY
        
        let blendImageMinX = min(outlineMinX, glyphMinX)
        let blendImageMaxY = max(outlineMaxY, glyphMaxY)
        let blendWidth = max(outlineMaxX, glyphMaxX) - blendImageMinX
        let blendHeight = blendImageMaxY - min(outlineMinY, glyphMinY)
        
        outRect.origin.x = Float(blendImageMinX)
        outRect.origin.y = Float(-blendImageMaxY) + outlineSize
        
        var index = 0, index2 = 0
        
        let blendImageSize = Int(blendWidth * blendHeight) * 2
        let blendImage = UnsafeMutablePointer<UInt8>.allocate(capacity: blendImageSize)
        memset(blendImage, 0, blendImageSize)
        
        var px = outlineMinX - blendImageMinX
        var py = blendImageMaxY - outlineMaxY
        for x in 0..<outlineWidth {
            for y in 0..<outlineHeight {
                index = Int(px + x + (py + y) * blendWidth)
                index2 = Int(x + (y * outlineWidth))
                blendImage[2 * index] = outlineBitmap[index2]
            }
        }
        
        px = glyphMinX - blendImageMinX
        py = blendImageMaxY - glyphMaxY
        for x in 0..<outWidth {
            for y in 0..<outHeight {
                index = Int(px) + Int(Int32(x) + ((Int32(y) + py) * blendWidth))
                index2 = Int(x + (y * outWidth))
                blendImage[2 * index + 1] = copyBitmap[index2]
            }
        }
        
        outRect.size.width  = Float(blendWidth)
        outRect.size.height = Float(blendHeight)
        outWidth  = UInt(blendWidth)
        outHeight = UInt(blendHeight)
        
        free(outlineBitmap)
        free(copyBitmap)
        ret = blendImage
        
        return (buffer: ret!, width: outWidth, height: outHeight, rect: outRect, xAdvance: xAdvance)
        
    }
    
    private var outlineSize: Float = 0
    internal var glyphCollection: GlyphCollection = .dynamic
    
    internal var stroker: FT_Stroker? = nil
}

internal extension Character {
    var unicodeScalarCodePoint: UInt {
        let characterString = String(self)
        let scalars = characterString.unicodeScalars
        
        return UInt(scalars[scalars.startIndex].value)
    }
}

fileprivate extension FreeTypeFont {
    
    func distanceMap(image: [UInt8], width: Int, height: Int) -> [UInt8] {
        let pixelAmount = (width + 2 * FreeTypeFont.distanceMapSpread) * (height + 2 * FreeTypeFont.distanceMapSpread)
        
        var xdist = [Int16](repeating: 0, count: pixelAmount)
        var ydist = [Int16](repeating: 0, count: pixelAmount)
        var gx      = [Double](repeating: 0, count: pixelAmount)
        var gy      = [Double](repeating: 0, count: pixelAmount)
        var data    = [Double](repeating: 0, count: pixelAmount)
        var outside = [Double](repeating: 0, count: pixelAmount)
        var inside  = [Double](repeating: 0, count: pixelAmount)
    
        // Convert img into double (data) rescale image levels between 0 and 1
        let outWidth = width + 2 * FreeTypeFont.distanceMapSpread
        for i in 0..<width {
            for j in 0..<height {
                data[j * outWidth + FreeTypeFont.distanceMapSpread + i] = Double(image[j * width + i]) / 255.0
            }
        }
        
        let width = width + 2 * FreeTypeFont.distanceMapSpread
        let height = height + 2 * FreeTypeFont.distanceMapSpread
        
        // Transform background (outside contour, in areas of 0's)
        computegradient(&data, Int32(width), Int32(height), &gx, &gy)
        edtaa3(&data, &gx, &gy, Int32(width), Int32(height), &xdist, &ydist, &outside)
        for i in 0..<pixelAmount {
            outside[i] = max(outside[i], 0)
        }
        
        // Transform foreground (inside contour, in areas of 1's)
        for i in 0..<pixelAmount {
            data[i] = 1.0 - data[i]
        }
        computegradient(&data, Int32(width), Int32(height), &gx, &gy)
        edtaa3(&data, &gx, &gy, Int32(width), Int32(height), &xdist, &ydist, &inside)
        for i in 0..<pixelAmount {
            inside[i] = max(inside[i], 0)
        }
        
        /* Single channel 8-bit output (bad precision and range, but simple) */
        var out = [UInt8](repeating: 0, count: pixelAmount)
        for i in 0..<pixelAmount {
            // The bipolar distance field is now outside-inside
            var dist = outside[i] - inside[i]
            dist = 128.0 - dist * 16.0
            if dist < 0 { dist = 0 }
            if dist > 255 { dist = 255 }
            out[i] = UInt8(dist)
        }
        
        return out
    }
}
