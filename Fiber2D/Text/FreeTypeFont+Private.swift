//
//  FreeTypeFont+Private.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 21.04.17.
//
//

import CFreeType

internal extension FreeTypeFont {
    
    internal static let distanceMapSpread: Int = 3
    
    // Internal static variables
    internal static var freeTypeInitialized = false
    internal static var library: FT_Library! {
        initFreeType()
        return _library
    }
    internal static var _library = FT_Library(bitPattern: 0)
    
    @discardableResult
    internal static func initFreeType() -> Bool {
        if !freeTypeInitialized {
            freeTypeInitialized = FT_Init_FreeType(&FreeTypeFont._library) != FT_Error(0)
        }
        
        return freeTypeInitialized
    }
    
    
    @discardableResult
    internal func createFontObject(name: String, size: Float) -> Bool {
        var face: FT_Face? = nil
        self.name = name
        
        if FreeTypeFont.cacheFontData[name] == nil {
            guard let fontData = try? FileLocator.shared.file(named: name)?.loadData() else {
                return false
            }
            
            FreeTypeFont.cacheFontData[name] = fontData
        }
        
        let fontData = [UInt8](FreeTypeFont.cacheFontData[name]!)
        guard FT_New_Memory_Face(FreeTypeFont.library, fontData, fontData.count, 0, &face) == FT_Error(0) else {
            return false
        }
        
        if FT_Select_Charmap(face, FT_ENCODING_UNICODE) != FT_Error(0) {
            var foundIndex = -1
            for i in 0..<Int(face!.pointee.num_charmaps) {
                if face!.pointee.charmaps[i]!.pointee.encoding != FT_ENCODING_NONE {
                    foundIndex = i
                    break
                }
            }
            
            guard foundIndex != -1 else { return false }
            self.encoding = face!.pointee.charmaps[foundIndex]!.pointee.encoding
            
            guard FT_Select_Charmap(face, self.encoding) == FT_Error(0) else {
                return false
            }
        }
        
        // set the requested font size
        let dpi: FT_UInt = 72
        let fontSizeInPoints = Int(64 * size * Setup.shared.contentScale)
        guard FT_Set_Char_Size(face, fontSizeInPoints, fontSizeInPoints, dpi, dpi) == FT_Error(0) else {
            return false
        }
        
        // store the face globally
        self.fontRef = face
        self.lineHeight = fontRef.pointee.size.pointee.metrics.height >> 6
        
        // done and good
        return true
    }
    
    internal func horizontalKernings(firstChar: UInt, secondChar: UInt) -> Int {
        // get the ID to the char we need
        let glyphIndex1 = FT_Get_Char_Index(fontRef, firstChar)
        
        guard glyphIndex1 != 0 else { return 0 }
        
        // get the ID to the char we need
        let glyphIndex2 = FT_Get_Char_Index(fontRef, secondChar)
        
        guard glyphIndex2 != 0 else { return 0 }
        
        var kerning = FT_Vector()
        
        guard FT_Get_Kerning(fontRef, glyphIndex1, glyphIndex2, FT_KERNING_DEFAULT.rawValue, &kerning) != 0 else {
            return 0
        }
        
        return kerning.x >> 6
    }
    
    internal func glyphBitmapWithOutline(for theChar: UInt, bbox: inout FT_BBox) -> UnsafeMutablePointer<UInt8>! {
        guard FT_Load_Char(fontRef, theChar, FT_Int32(FT_LOAD_NO_BITMAP)) == 0,
              fontRef.pointee.glyph.pointee.format == FT_GLYPH_FORMAT_OUTLINE else {
            return nil
        }
        
        var glyph: FT_Glyph? = nil
        guard FT_Get_Glyph(fontRef.pointee.glyph, &glyph) == 0 else {
            return nil
        }
        
        FT_Glyph_StrokeBorder(&glyph, stroker, 0, 1)
        guard glyph!.pointee.format == FT_GLYPH_FORMAT_OUTLINE else {
            FT_Done_Glyph(glyph)
            return nil
        }
       
        var outline = UnsafeRawPointer(glyph!).assumingMemoryBound(to: FT_OutlineGlyphRec_.self).pointee.outline
        FT_Glyph_Get_CBox(glyph, FT_GLYPH_BBOX_GRIDFIT.rawValue, &bbox)
        let width = (bbox.xMax - bbox.xMin) >> 6
        let rows  = (bbox.yMax - bbox.yMin) >> 6
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: width * rows)
        var bmp = FT_Bitmap()
        bmp.buffer = buffer
        bmp.width = UInt32(width)
        bmp.rows = UInt32(rows)
        bmp.pitch = Int32(width)
        bmp.pixel_mode = UInt8(FT_PIXEL_MODE_GRAY.rawValue)
        bmp.num_grays = 256
        
        var params = FT_Raster_Params()
        params.source = withUnsafePointer(to: &outline, { UnsafeRawPointer($0) })
        params.target = withUnsafePointer(to: &bmp, { $0 })
        params.flags = FT_RASTER_FLAG_AA
        FT_Outline_Translate(&outline,-bbox.xMin,-bbox.yMin)
        FT_Outline_Render(FreeTypeFont._library, &outline, &params)
        
        return bmp.buffer
    }
    
}
