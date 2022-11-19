//
//  Bundle.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/23/22.
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
        case watch = "com.colemancda.Lock.watchkitapp.watchkitextension"
        case lockKit = "com.colemancda.LockKit"
    }
}
