//
//  ActionEase.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath

public typealias EaseBlock = (Float) -> Float

public protocol EaseType {
    var calculationBlock: EaseBlock { get }
}

public enum EaseSine: EaseType {
    public var calculationBlock: EaseBlock {
        switch self {
        case .`in`:  return sineEaseIn
        case .out:   return sineEaseOut
        case .inOut: return sineEaseInOut
        }
    }

    case `in`, out, inOut
}

public struct ActionEaseContainer: ActionContainer, Continous {
    @inline(__always)
    mutating public func update(state: Float) {
        action.update(state: easeBlock(state))
    }
    
    public mutating func start(with target: AnyObject?) {
        elapsed = 0
        action.start(with: target)
    }
    
    public mutating func stop() {
        action.stop()
    }
    
    public mutating func step(dt: Time) {
        // same as continous
        elapsed += dt
        
        self.update(state: max(0, // needed for rewind. elapsed could be negative
            min(1, elapsed / max(duration, Float.ulpOfOne)) // division by 0
            )
        )
    }
    
    weak var target: AnyObject? = nil
    public var tag: Int = 0
    public let duration: Time
    private(set) public var elapsed:  Time = 0.0
    
    public var isDone: Bool {
        return elapsed > duration
    }
    
    private(set) var action: ActionContainer
    public let easeType: EaseType
    private let easeBlock: EaseBlock
    public init(action: ActionContainer, easeType: EaseType) {
        self.action = action
        self.easeType = easeType
        self.easeBlock = easeType.calculationBlock
        
        guard let action = action as? FiniteTime else {
            assertionFailure("ERROR: You can't ease an endless action.")
            // just to silence compiler error
            self.duration = 0.0
            return
        }
        self.duration = action.duration
    }
}

extension ActionContainer {
    public func ease(_ type: EaseType) -> ActionEaseContainer {
        return ActionEaseContainer(action: self, easeType: type)
    }
}
