//
//  DeviceManager.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import Bluetooth
import GATT
import CoreLock

public typealias LockManager = SmartLockManager<NativeCentral>

internal extension SmartLockManager where Central == NativeCentral {
    
    static var shared: SmartLockManager {
        
        return LockManagerCache.manager
    }
}

#if os(iOS)

import DarwinGATT

public typealias NativeCentral = DarwinCentral

private struct LockManagerCache {
    
    static let options = DarwinCentral.Options(showPowerAlert: false, restoreIdentifier: nil)
    
    static let central = DarwinCentral(options: options)
    
    static let manager = LockManager(central: central)
}

#endif


