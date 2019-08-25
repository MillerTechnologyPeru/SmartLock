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

public typealias LockManager = CoreLock.LockManager<NativeCentral>

public extension LockManager where Central == NativeCentral {
    
    static var shared: LockManager {
        return LockManagerCache.manager
    }
}

#if canImport(CoreBluetooth) && canImport(DarwinGATT)

import CoreBluetooth
import DarwinGATT

public typealias NativeCentral = DarwinCentral

private struct LockManagerCache {
    
    static let options = DarwinCentral.Options(showPowerAlert: false, restoreIdentifier: nil)
    
    static let central = DarwinCentral(options: options)
    
    static let manager = LockManager(central: central)
}

#endif


