//
//  Advertisement.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth

public extension AppleBeacon {
    
    static func smartLock(rssi: Int8) -> AppleBeacon {
        
        return AppleBeacon(uuid: .smartLockBeacon,
                           major: 0,
                           minor: 0,
                           rssi: rssi)
    }
}

public extension UUID {
    
    static var smartLockBeacon: UUID { return UUID(rawValue: "8BC4FB5E-AB9B-4F86-94C5-E2E37A62F0E6")! }
}

public extension BluetoothHostControllerInterface {
    
    /// LE Advertise with iBeacon
    func setSmartLockAdvertisingData(commandTimeout: HCICommandTimeout = .default) throws {
        
        try self.iBeacon(.smartLock(rssi: -10), // FIXME: RSSI
            flags: GAPFlags(flags: [.lowEnergyGeneralDiscoverableMode]),
            interval: .min)
    }
}
