//
//  Technique.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 24.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public final class Technique {
    internal(set) public var name = ""
    internal(set) public var passes = [Pass]()
    
    /** Adds a new pass to the Technique.
     Order matters. First added, first rendered
     */
    public func add(pass: Pass) {
        passes.append(pass)
    }
}
