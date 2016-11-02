//
//  WeakBox.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 02.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

public struct WeakBox<T> where T: AnyObject {
    public weak var value: T?
    
    public init(_ val: T) {
        self.value = val
    }
}

public extension Dictionary where Value: AnyObject {
    public mutating func removeUnusedObjects() {
        var weakDict = [Key: WeakBox<Value>]()
        
        for (k, v) in self {
            weakDict[k] = WeakBox(v)
        }
        
        removeAll()
        
        for (k, v) in weakDict {
            if let frame = v.value {
                self[k] = frame
            }
        }
    }
}
