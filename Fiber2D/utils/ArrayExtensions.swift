//
//  ArrayExtensions.swift
//  cocos2d-tests
//
//  Created by Andrey Volodin on 07.06.16.
//  Copyright © 2016 Cocos2d. All rights reserved.
//

import Foundation

extension Array {
	@discardableResult
    // FIXME: We need to get rid of this
    // The whole thing is very ugly and does not work the same on all platforms
    // We need to maintain this because Swift still can't treat :class protocol as AnyObject
    mutating func removeObject(_ obj: AnyObject) -> Bool {
        var idx = 0
        for e in self {
            #if os(iOS) || os(tvOS)
            if (e as AnyObject) === obj {
                remove(at: idx)
                return true
            }
            #else
            if (e as! AnyObject) === obj {
                remove(at: idx)
                return true
            }
            #endif
            idx += 1
        }

        return false
    }
}

public extension ContiguousArray where Element: AnyObject {
    @discardableResult
    mutating func remove(object: AnyObject) -> Bool {
        var idx = 0
        for e in self {
            if e === object {
                remove(at: idx)
                return true
            }
            idx += 1
        }

        return false
    }
}
