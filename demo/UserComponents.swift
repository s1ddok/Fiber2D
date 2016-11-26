//
//  UserComponents.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 27.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public class UpdateComponent: ComponentBase, Updatable {
    
    override init() {
        super.init()
        tag = 97
    }
    public func update(delta: Time) {
        //print("I'm updatable component. I'm updated with: \(delta)")
    }
}

public class FixedUpdateComponent: ComponentBase, FixedUpdatable {
    override init() {
        super.init()
        tag = 98
    }
    public func fixedUpdate(delta: Time) {
        //print("I'm fixed updatable component. I'm updated with \(delta)")
    }
}
