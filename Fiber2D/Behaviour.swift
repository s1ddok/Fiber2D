//
//  Behaviour.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 09.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/**
 * Behaviours are Components that can be enabled or disabled.
 */
public protocol Behaviour: Component {
    
    // Enabled Behaviours are Updated, disabled Behaviours are not
    var enabled: Bool { get set }
}
