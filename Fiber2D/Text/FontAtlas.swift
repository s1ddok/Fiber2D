//
//  FontAtlas.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 29.01.17.
//
//

import CFreeType

public struct FontLetterDefinition {
    var u, v: Float
    var width, height: Float
    var offsetX, offsetY: Float
    var textureID: Int
    var validDefinition: Bool
    var xAdvance: Int
}

public class FontAtlas {
    
    public static var cacheTextureWidth: Int = 512
    public static var cacheTextureHeight: Int = 512
    
    /** Removes textures atlas.
     It will purge the textures atlas and if multiple texture exist in the FontAtlas.
     */
    public static func purgeCache() {
        
    }
    
    public init(font: FreeTypeFont) {
        lineHeight = Float(font.maxHeight)
        self.font = font
        if font.isDistanceFieldEnabled {
            letterPadding += 2 * FreeTypeFont.distanceMapSpread
        }
        
    }
    
    public var font: FreeTypeFont
    public var lineHeight: Float = 0.0
    public func addLetterDefinition(for char: Character, definition: FontLetterDefinition) {
        
    }
    
    public func getLetterDefinition(for char: Character) -> FontLetterDefinition? {
        return nil
    }
    
    @discardableResult
    public func prepareLetterDefinitions(for string: String) -> Bool {
        return false
    }
    
    // MARK: Internal stuff
    
    internal var currentPage = 0
    internal var currentPageOrigX = 0
    internal var currentPageOrigY = 0
    internal var letterEdgeExtend = 2
    internal var letterPadding = 0
    
    internal var letterDefinitions = [Character: FontLetterDefinition]()
    
    internal func findNewCharacters(in string: String) -> [Character] {
        if letterDefinitions.isEmpty {
            return Array(string.characters)
        } else {
            return string.characters.filter { self.letterDefinitions[$0] == nil }
        }
    }
}
