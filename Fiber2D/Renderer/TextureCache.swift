//
//  TextureCache.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 02.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/** Singleton that handles the loading of textures.  Once the texture is loaded, the next time it will return
 * a reference of the previously loaded texture reducing GPU & CPU memory.
 */
public class TextureCache {
    /** Returns ths shared instance of the cache. */
    public static let shared = TextureCache()
    
    internal var textures = [String: Texture]()
    
    /**
     * Returns a Texture object given an file image.
     *
     * If the file image was not previously loaded, it will create a new Texture
     * object and it will return it. It will use the filename as a key.
     * Otherwise it will return a reference of a previously loaded image.
     *
     * Supported image extensions: .png
     *
     * @param fileimage Image file to load.
     *
     * @return A Texture object.
     */
    public func addImage(from filename: String) -> Texture? {
        let tex = textures[filename]
        
        guard tex == nil else {
            return tex
        }
        
        guard let file = FileLocator.shared.fileWithResolutionSearch(named: filename) else {
            print("Couldn't find file: \(filename)")
            return nil
        }
        
        let image = Image(file: file)
        let texture = Texture.make(from: image)
        textures[filename] = texture
        
        return texture
    }
    
    // TODO temporary method.
    public func add(texture: Texture, for key: String) {
        textures[key] = texture
    }

    /**
     *  Returns an already created texture. Returns nil if the texture doesn't exist.
     *
     *  @param key Key to look for.
     *
     *  @return Texture from cache.
     */
    public func texture(for key: String) -> Texture? {
        return textures[key]
    }
}

// MARK: Remove
public extension TextureCache {
    /** Purges the dictionary of loaded textures.
     * Call this method if you receive the "Memory Warning".
     * In the short term: it will free some resources preventing your app from being killed.
     * In the medium term: it will allocate more resources.
     * In the long term: it will be the same.
     */
    public func removeAllTextures() {
        textures.removeAll()
    }
    
    /** Removes unused textures.
     * Textures that have a retain count of 1 will be deleted.
     * It is convenient to call this method after when starting a new Scene.
     */
    public func removeUnusedTextures() {
        textures.removeUnusedObjects()
    }
    
    /**
     *  Deletes a texture from the cache given a texture.
     *
     *  @param texture Texture to remove from cache.
     */
    public func remove(texture: Texture) {
        for (k, v) in textures {
            if v === texture {
                textures[k] = nil
            }
        }
    }
    
    /**
     *  Deletes a texture from the cache given a its key name.
     *
     *  @param key Texture key to remove from cache.
     */
    public func removeTexture(for key: String) {
        textures.removeValue(forKey: key)
    }
}
