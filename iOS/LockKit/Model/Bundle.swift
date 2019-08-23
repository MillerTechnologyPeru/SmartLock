//
//  Bundle.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public extension Bundle {
    
    /// LockKit Bundle
    static var lockKit: Bundle {
        struct Cache {
            static let bundle = Bundle(for: Store.self)
        }
        return Cache.bundle
    }
}

public extension Bundle {
    
    enum Lock: String {
        
        case app = "com.colemancda.Lock"
        case coreLock = "com.colemancda.CoreLock"
        case lockKit = "com.colemancda.LockKit"
        case intent = "com.colemancda.Lock.Intent"
        case intentUI = "com.colemancda.Lock.IntentUI"
        case message = "com.colemancda.Lock.Message"
        case today = "com.colemancda.Lock.Today"
    }
}
