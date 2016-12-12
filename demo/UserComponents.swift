//
//  UserComponents.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 27.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import Fiber2D

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

public class EnterComponent: ComponentBase {
    override init() {
        super.init()
        tag = 96
    }
    
    public override func onAdd(to owner: Node) {
        super.onAdd(to: owner)
        
        owner.onEnter.subscribe(on: self, callback: EnterComponent.onEnter(self))
    }
    
    fileprivate func onEnter() {
        print("Owner did enter the active scene")
    }
    
}
