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
