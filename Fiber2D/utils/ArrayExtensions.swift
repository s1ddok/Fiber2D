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
    mutating func removeObject(_ obj: AnyObject) -> Bool {
        var idx = 0
        for e in self {
            if (e as AnyObject) === obj {
                remove(at: idx)
                return true
            }
            idx += 1
        }
        
        return false
    }
}
