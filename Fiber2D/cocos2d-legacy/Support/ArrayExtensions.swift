//
//  ArrayExtensions.swift
//  cocos2d-tests
//
//  Created by Andrey Volodin on 07.06.16.
//  Copyright © 2016 Cocos2d. All rights reserved.
//

import Foundation

extension Array {
    mutating func removeObject(_ obj: AnyObject) {
        var idx = 0
        for e in self {
            if (e as! AnyObject) === obj {
                remove(at: idx)
            }
            idx += 1
        }
    }
}
