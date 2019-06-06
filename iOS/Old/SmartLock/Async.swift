//
//  Async.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation

func mainQueue(_ block: @escaping () -> ()) {
    
    DispatchQueue.main.async(execute: block)
}

/// Perform a task on the internal queue.
func async(_ block: @escaping () -> ()) {
    
    queue.async(execute: block)
}

private let queue = DispatchQueue(label: "Smart Lock Queue")
