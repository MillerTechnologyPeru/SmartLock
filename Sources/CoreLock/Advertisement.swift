//
//  Advertisement.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth

public extension AppleBeacon {
    
    static func lock(rssi: Int8) -> AppleBeacon {
        
        return AppleBeacon(uuid: .lockBeacon,
                           major: 0,
                           minor: 0,
                           rssi: rssi)
    }
}

public extension UUID {
    
    static var lockBeacon: UUID { return UUID(rawValue: "8BC4FB5E-AB9B-4F86-94C5-E2E37A62F0E6")! }
}

public extension BluetoothHostControllerInterface {
    
    /// LE Advertise with iBeacon
    func setLockAdvertisingData(lock: UUID, rssi: Int8, commandTimeout: HCICommandTimeout = .default) throws {
        
        let beacon = AppleBeacon(uuid: lock, rssi: rssi)
        let flags: GAPFlags = [.lowEnergyGeneralDiscoverableMode, .notSupportedBREDR]
        
        try iBeacon(beacon, flags: flags, interval: .min)
    }
    
    /// LE Scan Response
    func setLockScanResponse(commandTimeout: HCICommandTimeout = .default) throws {
        
        let name: GAPCompleteLocalName = "Lock"
        let serviceUUID: GAPIncompleteListOf128BitServiceClassUUIDs = [UUID(bluetooth: LockService.uuid)]
        
        let encoder = GAPDataEncoder()
        let data = try encoder.encodeAdvertisingData(name, serviceUUID)
        
        try setLowEnergyScanResponse(data, timeout: commandTimeout)
    }
}
