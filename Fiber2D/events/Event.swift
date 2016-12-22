//
//  Event.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 27.11.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import Foundation

/// Create instances of `Event` and assign them to public constants on your class for each event type that your
/// class fires.
final public class Event<T> {
    public typealias EventCallback = (T) -> Void
    
    /// The number of times the `Event` has fired.
    public private(set) var fireCount: UInt = 0
    
    /// Whether or not the `Event` should retain a reference to the last data it was fired with. Defaults to false.
    public var retainLastData: Bool = false {
        didSet {
            if !retainLastData {
                lastDataFired = nil
            }
        }
    }
    
    /// The last data that the `Event` was fired with. In order for the `Event` to retain the last fired data, its
    /// `retainLastFired`-property needs to be set to true
    public private(set) var lastDataFired: T? = nil
    
    /// All the observers of to the `Event`.
    public var observers: [AnyObject] {
        get {
            return eventListeners.filter { $0.observer != nil }.map { $0.observer! }
        }
    }
    
    private var eventListeners = [EventSubscription<T>]()
    
    /// Initializer.
    ///
    /// - parameter retainLastData: Whether or not the Event should retain a reference to the last data it was fired
    ///   with. Defaults to false.
    public init(retainLastData: Bool = false) {
        self.retainLastData = retainLastData
    }
    
    /// Subscribes an observer to the `Event`.
    ///
    /// - parameter on: The observer that subscribes to the `Event`. Should the observer be deallocated, the
    ///   subscription is automatically cancelled.
    /// - parameter callback: The closure to invoke whenever the `Event` fires.
    /// - returns: A `EventSubscription` that can be used to cancel or filter the subscription.
    @discardableResult
    public func subscribe(on observer: AnyObject, callback: @escaping EventCallback) -> EventSubscription<T> {
        flushCancelledListeners()
        let EventListener = EventSubscription<T>(observer: observer, callback: callback);
        eventListeners.append(EventListener)
        return EventListener
    }
    
    /// Subscribes an observer to the `Event`. The subscription is automatically canceled after the `Event` has
    /// fired once.
    ///
    /// - parameter on: The observer that subscribes to the `Event`. Should the observer be deallocated, the
    ///   subscription is automatically cancelled.
    /// - parameter callback: The closure to invoke when the Event fires for the first time.
    @discardableResult
    public func subscribeOnce(on observer: AnyObject, callback: @escaping EventCallback) -> EventSubscription<T> {
        let EventListener = self.subscribe(on: observer, callback: callback)
        EventListener.once = true
        return EventListener
    }
    
    /// Fires the `Event`.
    ///
    /// - parameter data: The data to fire the `Event` with.
    public func fire(_ data: T) {
        fireCount += 1
        lastDataFired = retainLastData ? data : nil
        flushCancelledListeners()
        
        for eventListener in eventListeners {
            if eventListener.filter == nil || eventListener.filter!(data) == true {
                _ = eventListener.dispatch(data: data)
            }
        }
    }
    
    /// Cancels all subscriptions for an observer.
    ///
    /// - parameter for: The observer whose subscriptions to cancel
    public func cancelSubscription(for observer: AnyObject) {
        eventListeners = eventListeners.filter {
            if let definiteListener = $0.observer {
                return definiteListener !== observer
            }
            return false
        }
    }
    
    /// Cancels all subscriptions for the `Event`.
    public func cancelAllSubscriptions() {
        eventListeners.removeAll(keepingCapacity: false)
    }
    
    /// Clears the last fired data from the `Event` and resets the fire count.
    public func clearLastData() {
        lastDataFired = nil
    }
    
    // MARK: - Private Interface
    
    private func flushCancelledListeners() {
        var removeListeners = false
        for EventListener in eventListeners {
            if EventListener.observer == nil {
                removeListeners = true
                break
            }
        }
        if removeListeners {
            eventListeners = eventListeners.filter {
                return $0.observer != nil
            }
        }
    }
}

/// A EventLister represenents an instance and its association with a `Event`.
final public class EventSubscription<T> {
    public typealias EventCallback = (T) -> Void
    public typealias EventFilter   = (T) -> Bool
    
    // The observer.
    weak public var observer: AnyObject?
    
    /// Whether the observer should be removed once it observes the `Event` firing once. Defaults to false.
    public var once = false

    fileprivate var filter:   EventFilter?
    fileprivate var callback: EventCallback

    fileprivate init(observer: AnyObject, callback: @escaping EventCallback) {
        self.observer = observer
        self.callback = callback
    }
    
    /// Assigns a filter to the `EventSubscription`. This lets you define conditions under which a observer should actually
    /// receive the firing of a `Event`. The closure that is passed an argument can decide whether the firing of a
    /// `Event` should actually be dispatched to its observer depending on the data fired.
    ///
    /// If the closeure returns true, the observer is informed of the fire. The default implementation always
    /// returns `true`.
    ///
    /// - parameter predicate: A closure that can decide whether the `Event` fire should be dispatched to its observer.
    /// - returns: Returns self so you can chain calls.
    @discardableResult
    public func filter(_ predicate: @escaping EventFilter) -> EventSubscription {
        self.filter = predicate
        return self
    }
    
    /// Cancels the observer. This will cancelSubscription the listening object from the `Event`.
    public func cancel() {
        self.observer = nil
    }
    
    // MARK: - Private Interface
    
    fileprivate func dispatch(data: T) -> Bool {
        guard observer != nil else {
            return false
        }
        
        if once {
            observer = nil
        }
        callback(data)
        
        return observer != nil
    }
}
