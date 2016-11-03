//
//  File.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 03.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import Foundation

internal let BUFFER_SIZE = 32*1024

/**
 Meta data of a file describing certain details.
 */
public struct FileMetaData {
    /**
     The filename to be actually used. Spritebuilder is making use of this to alias filenames, like a wav file becoming an ogg file for Android platforms.
     */
    public var filename: String
    
    /**
     A dictionary containing a filename per languageID. Structure looks like this:
     
     {
     "es" : "path/to/file-es.exension",
     "en" : "path/to/file-en.exension"
     }
     */
    public var localizations: [String: String]?
    
    /**
     Whether an image should be scaled for UI purposes or not.
     */
    public var isUseUIScale = false
    
    public var localizedFileName: String {
        if let localizations = self.localizations {
            for languageId in Locale.preferredLanguages {
                if let filenameForLanguageID = localizations[languageId] {
                    return filenameForLanguageID
                }
            }
        }
    
        return filename
    }
    
    
    public init(dictionary: [String: Any]) {
        self.filename = dictionary["filename"] as! String
        self.isUseUIScale = Bool(dictionary["UIScale"] as! String) ?? false
        self.localizations = dictionary["localizations"] as? [String: String]
    }
}

/**
 Abstract file handling class. Files may reference local or remote files, such as files on an HTTP or FTP server.
 */
public final class File {
    /**
     Name of the original file requested from FileLocator. (Ex: "Sprites/Hero.png")
     This may not exactly match the path of the file FileLocator actually finds if the file on disk is aliased or tagged with a resolution.
     */
    private(set) public var name: String
    
    /**
     URL of the file found by FileLocator.
     */
    private(set) public var url: URL
    
    /**
     The absolute path of the file if it is a local file. `nil` if the file is a remote file.
     */
    public var absoluteFilePath: String? {
        if url.isFileURL {
            return url.path
        }
        
        return nil
    }
    
    /**
     Content scale the file should be interpreted as.
     
     @see FileLocator for more information on about asset content scales.
     */
    private(set) public var contentScale: Float
    
    /**
     If the file is tagged with an explicit resolution. (ex: "Hero-2x.png" vs "Hero.png") This is important for certain assets such as images.
     Untagged images are treated as having a content scale of FileLocator.untaggedContentScale and are rescaled to more closely match the device when loaded.
     */
    private(set) public var hasResolutionTag: Bool
    
    /**
     Assume the file is a plist and read it's contents.
     
     @return The plist file's contents, or nil if there is an error.
     */
    func loadPlist() throws -> Any {
        
        let stream = openInputStream()
        
        let plist = try PropertyListSerialization.propertyList(with: stream, options: [], format: nil)
        
        stream.close()
        
        return plist
    }
    
    /**
     Load the file's contents into a data object.
     
     @return The file's complete contents in a data object.
     */
    func loadData() throws -> Data {
        if shouldLoadDataFromStream {
            let stream = openInputStream()
            let data = try stream.loadData(sizeHint: 0)
            stream.close()
            
            return data
        } else {
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            return data
        }
    }
    
    /**
     Load the file's contents as a UTF8 string.
     
     @return The file's complete contents as a UTF8 string.
     */
    func loadString() throws -> String {
        return String(data: try loadData(), encoding: .utf8)!
    }
    
    /**
     Opens an input stream to the file so it can be read sequentially.
     
     @return An opened stream object.
     */
    public func openInputStream() -> InputStream {
        guard let stream = InputStream(url: url) else {
            fatalError("Can't open input stream for \(self.name)")
        }
        
        stream.open()
        return stream
    }
    
    /**
     Indicate whether an asset should be scaled for UI purposes or not
     
     @return If the asset should be scaled for UI.
     */
    internal(set) public var isUseUIScale = false
    
    internal var shouldLoadDataFromStream: Bool = false
    
    internal var autoScaleFactor: Float {
        if hasResolutionTag { return 1.0 }
        else {
            let relativeScale = max(1.0, self.contentScale / Setup.shared.assetScale)
            return 1.0 / Float(UInt(relativeScale).nextPOT)
        }
    }

    
    init(name: String, url: URL, contentScale: Float, tagged: Bool) {
        self.name = name
        self.url = url
        self.contentScale = contentScale
        self.hasResolutionTag = tagged
    }
}


fileprivate extension InputStream {
    fileprivate func loadData(sizeHint: UInt) throws -> Data {
        let hint = sizeHint == 0 ? BUFFER_SIZE : Int(sizeHint)
        var buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: hint)
        var totalBytesRead = read(buffer, maxLength: hint)

        while hasBytesAvailable {
            let newSize = totalBytesRead * 3 / 2
            // Ehhhh, Swift Foundation's Data doesnt have `increaseLength(by:)` method anymore
            // That is why we have to go the `realloc` way... :(
            buffer = unsafeBitCast(realloc(buffer, MemoryLayout<UInt8>.size * newSize), to: UnsafeMutablePointer<UInt8>.self)
            totalBytesRead += read(buffer.advanced(by: totalBytesRead), maxLength: newSize - totalBytesRead)
        }
        
        if streamStatus == .error {
            throw streamError!
        }
        
        // FIXME: Probably should use Data(bytesNoCopy: .. ) instead, but will it deallocate the tail of not used buffer?
        // leak check must be done
        let retVal = Data(bytes: buffer, count: totalBytesRead)
        free(buffer)
        return retVal
    }
}
