//
//  FileLocator.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 03.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import Foundation

internal struct FileLocatorSearchOptions {
    internal var shouldSkipResolutionSearch = true
    
    internal static let `default` = FileLocatorSearchOptions()
}

/**
 Class to find assets in search paths taking localization and image content scales into account.
 
 General idea is to provide the filename only and depending on the device's settings and capabilities(resolution) an appropriate File instance is returned.
 
 There are two methods available to access files: fileNamedWithResolutionSearch and fileNamed. fileNamedWithResolutionSearch is supposed to be used for image lookups as well as other files containing a resolution specific tag if you like to optimize visual quality depending on the device's resolution. See below.
 FileNamed works for any file.
 
 Images are searched for depending on the device's content scale and the availability of an image's resolution variants.
 You can provide three different content scale variants in a bundle: 1x, 2x and 4x. The naming convention is <FILENAME>-<CONTENTSCALE>x.<EXETENSION> for explicitly tagged files.
 Example Hero.png:
 * Hero-1x.png
 * Hero-2x.png
 * Hero-4x.png
 
 If the explicit content scale tag is omitted then it's content scale is determined by the property untaggedContentScale.
 
 The search will try to match the device's content scale first. If there is no matching variant then file utils will look for an image which content scale is at max 2x greater than the device's content scale.
 If there is none it will look for the next lower POT scale and so on.
 
 Explicitly tagged files take precedence over untagged images.
*/
public final class FileLocator {
    /**
     Returns a singleton instance of the file utils.
     
     @return An shared instance of this class
     */
    public static let shared = FileLocator()
    
    /**
     Base content scale for untagged, automatically resized assets.
     Required to be a power of two. Fully supported values: 4, 2 and 1
     */
    public var untaggedContentScale: UInt = 1
    
    /**
     All paths that will be searched for assets. Provide full directory paths.
     
     Changing the searchPaths will purge the cache.
     */
    public var searchPaths: [String] = [Bundle.main.resourcePath!] {
        didSet {
            purgeCache()
        }
    }
    
    /**
     Returns an instance of FileMetaData for a given filename and search path.
     
     @param filename   The filename to search for. Note: filenames are the relative path to a search path including the filename, e.g. images/vehicles/car
     @param searchPath A search path for the filename.
     
     @return Metadata of the filename and search path pair.
     */
    public func metaData(for filename: String, in searchPath: String) -> FileMetaData? {
        if let metadata = metadataDictionaries[searchPath]?[filename] {
            return FileMetaData(dictionary: metadata)
        }
        return nil
    }
 
    /**
     Returns an instance of File if a file was found.
     This method is meant to be used for images and other files that have a resolution tag included in their names as it will search for resolutions matching the device's content scale.
     
     See header for details on search order.
     
     @param filename the file's filename to search for. Note: filenames are the relative path to a search path including the filename, e.g. images/vehicles/car.png
     @param error    On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information. You may specify nil for this parameter if you do not want the error information.
     
     @return An instance of File pointing to a file found. If an error occured nil is returned and assigns an appropriate error object to the error parameter.
     */
    public func fileWithResolutionSearch(named filename: String) -> File? {
        let options = FileLocatorSearchOptions(shouldSkipResolutionSearch: false)
        return find(filename: filename, options: options)
    }
    
    /**
     Returns an instance of File if a file was found.
     This method is meant to be used for non-images as it will NOT search for resolutions matching the device's content scale like fileNamedWithResolutionSearch does.
     
     @param filename the filename to search for. Note: filenames are the relative path to a search path including the filename, e.g. sounds/vehicles/honk.wav
     @param error    On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information. You may specify nil for this parameter if you do not want the error information.
     
     @return An instance of File pointing to a file found. If an error occured nil is returned and assigns an appropriate error object to the error parameter.
     */
    public func file(named filename: String) -> File? {
        return find(filename: filename, options: .default)
    }
    
    /**
     Purges the cache used internally. If assets get invalid(move, delete) invoking this method can help get rid of false positives.
     */
    public func purgeCache() {
        cache.removeAll()
    }
    
    // MARK: Internal stuff
    internal var cache = [String: File]()
                                      // Search path  Filename  Metadata plist dict
    internal var metadataDictionaries = [String:     [String:   [String: Any]]]()
 
}

internal extension FileLocator {
    
    internal func find(filename: String, options: FileLocatorSearchOptions) -> File? {
        if let cachedFile = cache[filename] {
            return cachedFile
        }
        
        return findInAllSearchPaths(filename: filename, options: options)
    }
    
    internal func findInAllSearchPaths(filename: String, options: FileLocatorSearchOptions) -> File? {
        for searchPath in searchPaths {
            let metadata = metaData(for: filename, in: searchPath)
            let resolvedFilename = metadata?.localizedFileName ?? filename
            
            if let file = find(filename: resolvedFilename, in: searchPath, options: options) {
                if let metadata = metadata {
                    file.isUseUIScale = metadata.isUseUIScale
                }
                
                cache[filename] = file
                return file
            }
        }
        
        return nil
    }
    
    internal func find(filename: String, in searchPath: String, options: FileLocatorSearchOptions) -> File? {
        var ret: File? = nil
        
        tryVariants(for: filename, options: options) { name, contentScale, tagged in
            let fileURL = URL(fileURLWithPath: searchPath).appendingPathComponent(name)
            let filemanager = FileManager.default
            
            if filemanager.fileExists(atPath: fileURL.path) {
                ret = File(name: filename, url: fileURL, contentScale: contentScale, tagged: tagged)
                return true
            }
            
            return false
        }
        
        return ret
    }
    
    internal func tryVariants(for filename: String, options: FileLocatorSearchOptions, block: (String, Float, Bool) -> Bool) {
        if options.shouldSkipResolutionSearch {
            _ = block(filename, 1.0, true)
        } else {
            var contentScale = UInt(Setup.shared.assetScale).nextPOT
            
            var name = contentScaleFilename(with: filename, contentScale: contentScale)
            
            if block(name, Float(contentScale), true) { return }
            
            if block(filename, Float(untaggedContentScale), false) { return }
            
            while true {
                contentScale /= 2
                
                if contentScale < 1 { break }
                
                name = contentScaleFilename(with: filename, contentScale: contentScale)
                if block(name, Float(contentScale), true) { return }
            }
        }
    }
    
    internal func contentScaleFilename(with baseFilename: String, contentScale: UInt, separator: Character = Character("-")) -> String {
        var base = URL(fileURLWithPath: baseFilename).deletingPathExtension().absoluteString
        var ext = URL(fileURLWithPath: baseFilename).pathExtension
        
        // Need to handle multiple extensions. (ex: .pvr.gz)
        while URL(fileURLWithPath: base).pathExtension.characters.count > 0 {
            ext = "\(URL(fileURLWithPath: base).pathExtension).\(ext)"
            base = URL(fileURLWithPath: base).deletingPathExtension().absoluteString
        }
        
        return "\(base)\(separator)\(contentScale).\(ext)"
    }
}
