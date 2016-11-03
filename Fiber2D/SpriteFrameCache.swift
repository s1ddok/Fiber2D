//
//  SpriteFrameCache.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 01.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftBGFX
import SwiftMath
import Foundation

/**
 Singleton that manages the loading and caching of sprite frames.
 
 ### Supported editors (Non exhaustive)
 
 - Texture Packer http://www.codeandweb.com/texturepacker
 - zwoptex http://www.zwopple.com/zwoptex/
 */
internal class SpriteFrameCache {
    /** Sprite frame cache shared instance. */
    internal static let shared = SpriteFrameCache()
    
    // Sprite frame dictionary.
    internal var spriteFrames = [String: SpriteFrame]()
    
    // Sprite frame plist file name set.
    internal var loadedFilenames = Set<String>()
    
    // Sprite frame file lookup dictionary.
    internal var spriteFrameFileLookup = [String : String]()
    
    /// @name Sprite Frame Cache Addition
    /**
     *  Add Sprite frames to the cache from the specified plist.
     *
     *  @param plist plist description.
     */
    internal func addSpriteFrames(from plist: String) {
        guard !loadedFilenames.contains(plist) else {
            return
        }
    }
    
    /**
     *  Add a sprite frame to the cache with the specified sprite frame and name.  If name already exists, sprite frame will be overwritten.
     *
     *  @param frame     Sprite frame to use.
     *  @param frameName Frame name to use.
     */
    internal func add(frame: SpriteFrame, name: String) {
        spriteFrames[name] = frame
    }

    /// @name Sprite Frame Cache Access
    /**
     *  Returns a SpriteFrame from the cache using the specified name.
     *
     *  @param name Name to lookup.
     *
     *  @return The SpriteFrame object.
     */
    internal func spriteFrame(by name: String) -> SpriteFrame! {
        var frame = spriteFrames[name] 
        
        if let _ = FileLocator.shared.fileWithResolutionSearch(named: name) {
            let texture = Texture.load(from: name)!
            return texture.spriteFrame
        }
        
        if frame == nil {
            let pathComponents = name.components(separatedBy: "/")
            
            for len in stride(from: pathComponents.count - 1, to: 0, by: -1) {
                let path = pathComponents[0...len].joined(separator: "/") + ".plist"
                
                if let _ = FileLocator.shared.file(named:path) {
                    addSpriteFrames(from: path)
                    
                    frame = spriteFrames[name]
                    
                    if frame != nil {
                        break
                    }
                }

            }
            
        }
        return frame
    }
    
    private func add(frame: SpriteFrame, frameName: String, pathPrefix: String) {
        self.spriteFrames[frameName] = frame
        // Add an alias that allows spriteframe files to be treated as directories.
        // Ex: A frame named "bar.png" in a spritesheet named "bar.plist" will add both "bar.png" and "foo/bar.png" to the dictionary.
        if pathPrefix != "" && !frameName.hasPrefix(pathPrefix) {
            let key = URL(fileURLWithPath: pathPrefix).appendingPathComponent(frameName).absoluteString
            self.spriteFrames[key] = frame
        }
    }
    
    /**
     *  Registers a sprite sheet with the sprite frame cache so that the sprite frames can be loaded by name.
     *
     *  @param plist Sprite sheet file.
     */
    private func registerSpriteFramesFile(plistFile: String) {
        guard let file = FileLocator.shared.fileWithResolutionSearch(named: plistFile) else {
            fatalError("Error finding \(plistFile)")
        }

        guard let dict = (try? file.loadPlist()) as? [String: Any] else {
            fatalError("Error finding \(plistFile)")
        }
        
        let metadataDict = dict["metadata"] as? [String: Any]
        var format = 0
        // get the format
        if let metadataDict = metadataDict {
            format = Int(metadataDict["format"] as! String)!
        }
        // check the format
        guard (2...3).contains(format) else {
            fatalError("format is not supported for SpriteFrameCache")
        }
        
        guard let framesDict = dict["frames"] as? [String: Any] else {
            fatalError("plist doesn't have any frame info")
        }
        for frameDictKey in framesDict.keys {
            spriteFrameFileLookup[frameDictKey] = plistFile
        }
    }
    
}

// MARK: Remove methods
internal extension SpriteFrameCache {
    /// @name Sprite Frame Cache Removal
    /**
     *  Remove all sprite frames.
     */
    internal func removeSpriteFrames() {
        spriteFrames.removeAll()
        loadedFilenames.removeAll()
    }
    
    /**
     *  Remove unused sprite frames e.g. Sprite frames that have a retain count of 1.
     */
    internal func removeUnusedSpriteFrames() {
        spriteFrames.removeUnusedObjects()
    }
    
    /**
     *  Remove the specified sprite frame from the cache.
     *
     *  @param name Sprite frame name.
     */
    internal func removeSpriteFrame(by name: String) {
        spriteFrames.removeValue(forKey: name)
        
        // XXX. Since we don't know the .plist file that originated the frame, we must remove all .plist from the cache
        loadedFilenames.removeAll()
    }
    
    /**
     *  Remove sprite frames detailed in the specified plist.
     *
     *  @param plist list file to use.
     */
    internal func removeSpriteFrames(from plist: String) {
        guard let file = FileLocator.shared.file(named: plist) else {
            fatalError("Error finding: \(plist)")
        }
        
        guard let dict = (try? file.loadPlist()) as? [String: Any] else {
            fatalError("Error finding: \(plist)")
        }
        
        remove(from: dict)
        
        loadedFilenames.remove(plist)
    }
    
    /**
     *  Remove sprite frames associated with the specified texture.
     *
     *  @param texture Texture to reference.
     */
    internal func removeSpriteFrames(from texture: Texture) {
        for (k, v) in spriteFrames {
            if v.texture === texture {
                spriteFrames[k] = nil
            }
        }
    }
    
    fileprivate func remove(from dictionary: [String: Any]) {
        let dict = dictionary["frames"] as! [String: Any]
        
        for k in dict.keys {
            spriteFrames.removeValue(forKey: k)
        }
    }
}

// MARK: Convinence inits for SpriteFrame
internal extension SpriteFrame {
    internal convenience init(rect: Rect, rotated: Bool, offset: Point, untrimmedSize: Size, textureHeight: Float, contentScale: Float) {
        var rect = rect
        // Flip the y values before scaling.
        let h = rotated ? rect.size.width : rect.size.height
        rect.origin.y = textureHeight - (rect.origin.y + h)
        rect = rect.scaled(by: 1.0 / contentScale)
        let offset = offset * (1.0 / contentScale)
        let untrimmedSize = untrimmedSize * (1.0 / contentScale)
        self.init(texture: nil, rect: rect, rotated: rotated, trimOffset: offset, untrimmedSize: untrimmedSize)
    }
    
    internal convenience init?(format: Int, frameDict: [String : String], aliases: inout [String], textureHeight: Float, contentScale: Float) {
        switch format {
        case 2:
            let rect = Rect(frameDict["frame"]!)
            let rotated = Bool(frameDict["rotated"]!)!
            let offset = Point(frameDict["offset"]!)
            let untrimmedSize = Size(frameDict["sourceSize"]!)
            self.init(rect: rect, rotated: rotated, offset: offset, untrimmedSize: untrimmedSize, textureHeight: textureHeight, contentScale: contentScale)
        case 3:
            let spriteSize = Size(frameDict["spriteSize"]!)
            let textureRect = Rect(frameDict["textureRect"]!)
            let rect = Rect(origin: textureRect.origin, size: spriteSize)
            let offset = Point(frameDict["spriteOffset"]!)
            let untrimmedSize = Size(frameDict["spriteSourceSize"]!)
            let rotated = Bool(frameDict["textureRotated"]!)!
            
            //aliases.append(contentsOf: frameDict["aliases"] as! [String])
            
            self.init(rect: rect, rotated: rotated, offset: offset, untrimmedSize: untrimmedSize, textureHeight: textureHeight, contentScale: contentScale)
        default: return nil
        }
    }
}
