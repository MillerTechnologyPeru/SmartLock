//
//  Queue.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation

/// Perform task on main queue
public func mainQueue(_ block: @escaping () -> ()) {
    DispatchQueue.main.async(execute: block)
}

public extension DispatchQueue {
    
    convenience init<T>(for type: T.Type,
                        in bundle: Bundle.Lock = .app,
                        qualityOfService: DispatchQoS = .default,
                        isConcurrent: Bool = false) {
        
        let label = bundle.rawValue + "." + "\(type)"
        self.init(label: label, qos: .default,
                  attributes: isConcurrent ? .concurrent : [],
                  autoreleaseFrequency: .inherit,
                  target: nil)
    }
}

@available(*, deprecated, message: "Use Task instead")
public extension DispatchQueue {
    
    /// Lock App GCD Queue
    static var app: DispatchQueue {
        struct Cache {
            static let queue = DispatchQueue(
                label: Bundle.Lock.app.rawValue,
                qos: .userInitiated,
                attributes: [.concurrent]
            )
        }
        return Cache.queue
    }
    
    /// Lock Bluetooth operations GCD Queue
    static var log: DispatchQueue {
        struct Cache {
            static let queue = DispatchQueue(
                label: Bundle.Lock.app.rawValue + ".Log",
                qos: .utility
            )
        }
        return Cache.queue
    }
    
    /// Lock iCloud GCD Queue
    static var cloud: DispatchQueue {
        struct Cache {
            static let queue = DispatchQueue(
                label: Bundle.Lock.app.rawValue + ".iCloud",
                qos: .utility
            )
        }
        return Cache.queue
    }
}
