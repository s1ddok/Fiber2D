//
//  BehaviourProtocol.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 25.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public protocol Pausable {
    var paused: Bool { get set }
}

public protocol Updatable: class, Prioritized {
    func update(delta: Time)
}

public protocol FixedUpdatable: class, Prioritized {
    func fixedUpdate(delta: Time)
}

// TODO: Isn't really used anywhere yet
public protocol LateUpdatable: class, Prioritized {
    func lateUpdate(delta: Time)
}

public protocol Enterable {
    func onEnter()
}

public protocol Exitable {
    func onExit()
}
