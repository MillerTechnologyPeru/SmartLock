//
//  Log.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import Foundation

public func log(_ message: String) {
    DispatchQueue.main.async {
        NSLog(message)
    }
}
