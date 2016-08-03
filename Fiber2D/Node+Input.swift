//
//  Node+Touch.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation

extension Node {
    /** Returns YES, if touch is inside sprite
     Added hit area expansion / contraction
     Override for alternative clipping behavior, such as if you want to clip input to a circle.
     */
    override func hitTestWithWorldPos(_ pos: CGPoint) -> Bool {
        let p = self.convertToNodeSpace(pos)
        let h = CGFloat(-hitAreaExpansion)
        let offset: CGPoint = ccp(-h, -h)
        let size: CGSize = CGSize(width: self.contentSizeInPoints.width - offset.x, height: self.contentSizeInPoints.height - offset.y)
        return !(p.y < offset.y || p.y > size.height || p.x < offset.x || p.x > size.width)
    }
    
    override func clippedHitTestWithWorldPos(_ pos: CGPoint) -> Bool {
        // If *any* parent node clips input and we're outside their clipping range, reject the hit.
        guard parent == nil || !parent!.rejectClippedInput(pos) else {
            return false
        }
        
        return self.hitTestWithWorldPos(pos)
    }
    
    func rejectClippedInput(_ pos: CGPoint) -> Bool {
        // If this clips input, do the bounds test to clip against this node
        if self.clipsInput && !self.hitTestWithWorldPos(pos) {
            // outside of this node, reject this!
            return true
        }
        guard let parent = self.parent else {
            // Terminating condition, the hit was not rejected
            return false
        }
        return parent.rejectClippedInput(pos)
    }
}
