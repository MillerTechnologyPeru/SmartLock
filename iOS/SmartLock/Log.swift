//
//  Log.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import LockKit

// MARK: - Logging

extension Log {
    
    static var mainApp: Log {
        struct Cache {
            static let log: Log = {
                do { return try Log.Store.lockAppGroup.create(date: Date(), bundle: .main) }
                catch { assertionFailure("Could not create log file: \(error)"); return .appCache }
            }()
        }
        return Cache.log
    }
}
