//
//  Keychain.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import KeychainAccess

public enum KeychainGroup: String {
    
    case lock = "4W79SG34MW.com.colemancda.Lock"
}

public enum KeychainService: String {
    
    case lock = "com.colemancda.Lock"
}

public extension Keychain {
    
    convenience init(accessGroup: KeychainGroup) {
        self.init(accessGroup: accessGroup.rawValue)
    }
    
    convenience init(service: KeychainService, accessGroup: KeychainGroup) {
        self.init(service: service.rawValue, accessGroup: accessGroup.rawValue)
    }
}
