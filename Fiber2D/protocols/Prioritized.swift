//
//  Prioritized.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 25.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public protocol Prioritized {
    // Used to break ties for scheduled blocks, updated: and fixedUpdate: methods.
    // Targets are sorted by priority so lower priorities are called first.
    // The priority value for a given object should be constant.
    var priority: Int { get }
}

public extension Prioritized {
    var priority: Int {
        return 0
    }
}
