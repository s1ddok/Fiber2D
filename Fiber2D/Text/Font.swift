//
//  Font.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 29.01.17.
//
//

/**
 * @brief Possible GlyphCollection used by Label.
 *
 * Specify a collections of characters to be load when Label created.
 * Consider using .dynamic.
 */
public enum GlyphCollection {
    case dynamic
    case nehe
    case ascii
    case custom(String)
    
    public var glyphString: String? {
        switch self {
        case .dynamic: return nil
        case .nehe: return GlyphCollection.glyphNEHE
        case .ascii: return GlyphCollection.glyphASCII
        case .custom(let customGlyphs): return customGlyphs
        }
    }
    
    internal static let glyphASCII = "\"!#$%&'()*+,-./0123456789:<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþ "
    internal static let glyphNEHE = "!\"#$%&'()*+,-./0123456789:<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ "
}

public protocol Font {
    var fontAtlas: FontAtlas { get }
    var maxHeight: Int { get }
    
    func horizontalKernings(for text: String) -> [Int]!
}
