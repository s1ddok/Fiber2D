//
//  Tree.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 18.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

internal final class Tree<T> {
    public var value: T
    
    fileprivate(set) public weak var parent: Tree<T>?
    fileprivate(set) public var children: [Tree<T>] = []
    
    public init(value: T) {
        self.value = value
    }
    
    public func add(child: Tree<T>) {
        guard child.parent == nil else {
            fatalError("Can't add a child that already has a parent")
        }
        child.parent = self
        children.append(child)
    }
}

internal typealias UInt8Tree = Tree<UInt8>

internal extension Array where Element: UInt8Tree {
    internal func childrenFirstTraverse() -> [UInt8] {
        var retVal = [UInt8]()
        
        for e in self {
            recursivelyPutChildren(from: e, into: &retVal)
        }
        return retVal
    }

}

fileprivate func recursivelyPutChildren(from tree: Tree<UInt8>, into array: inout [UInt8]) {
    for c in tree.children {
        recursivelyPutChildren(from: c, into: &array)
    }
    
    array.append(tree.value)
}
