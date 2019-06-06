//
//  DeviceManager.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 6/5/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import SwiftUI
import Bluetooth
import GATT
import CoreLock

public typealias LockManager = CoreLock.LockManager<NativeCentral>
public typealias LockPeripheral = CoreLock.LockPeripheral<NativeCentral>
public typealias Peripheral = NativeCentral.Peripheral

extension CoreLock.LockPeripheral: Identifiable {
    
    public var id: Central.Peripheral {
        return scanData.peripheral
    }
}

internal extension LockManager where Central == NativeCentral {
    
    static var shared: LockManager {
        return LockManagerCache.manager
    }
}

#if canImport(DarwinGATT)
import DarwinGATT

public typealias NativeCentral = DarwinCentral

private struct LockManagerCache {
    
    static let options = DarwinCentral.Options(showPowerAlert: false, restoreIdentifier: nil)
    static let central = DarwinCentral(options: options)
    static let manager = LockManager(central: central)
}

#endif
