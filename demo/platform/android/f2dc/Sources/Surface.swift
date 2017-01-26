//
//  Surface.swift
//  Fiber2D-demo
//
//  Created by Andrey Volodin on 15.12.16.
//
//

import CSDL2

public class Surface {
    internal let handle: UnsafeMutablePointer<SDL_Surface>
    
    public init(handle: UnsafeMutablePointer<SDL_Surface>) {
        self.handle = handle
    }
}
