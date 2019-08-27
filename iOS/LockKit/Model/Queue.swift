//
//  Queue.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation

public func mainQueue(_ block: @escaping () -> ()) {
    
    DispatchQueue.main.async(execute: block)
}

/// Perform a task on the internal queue.
public func async(_ block: @escaping () -> ()) {
    
    appQueue.async(execute: block)
}

internal let appQueue = DispatchQueue(label: Bundle.Lock.app.rawValue)

public extension DispatchQueue {
    
    convenience init<T>(for type: T.Type,
                        in bundle: Bundle.Lock,
                        qualityOfService: DispatchQoS = .default,
                        isConcurrent: Bool = false) {
        
        let label = bundle.rawValue + "." + "\(type)"
        self.init(label: label, qos: .default,
                  attributes: isConcurrent ? .concurrent : [],
                  autoreleaseFrequency: .inherit,
                  target: nil)
    }
}
