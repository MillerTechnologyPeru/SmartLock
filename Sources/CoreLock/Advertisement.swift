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
    func setSmartLockAdvertisingData(lock: UUID, rssi: Int8, commandTimeout: HCICommandTimeout = .default) throws {
        
        try iBeacon(AppleBeacon(uuid: lock, rssi: rssi),
                    flags: GAPFlags(flags: [.lowEnergyGeneralDiscoverableMode]),
                    interval: .min)
    }
    
    /// LE Scan Response
    func setSmartLockScanResponse(commandTimeout: HCICommandTimeout = .default) throws {
        
        let name: GAPCompleteLocalName = "Lock"
        let serviceUUID: GAPIncompleteListOf128BitServiceClassUUIDs = [UUID(bluetooth: LockService.uuid)]
        
        let data = GAPDataEncoder.encode([name, serviceUUID])
        
        guard let scanResponseData = LowEnergyAdvertisingData(data: data)
            else { fatalError("\(data) > 31 bytes") }
        
        try setLowEnergyScanResponse(scanResponseData, timeout: commandTimeout)
    }
}
