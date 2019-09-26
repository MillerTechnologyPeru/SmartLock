//
//  Advertisement.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth


#if os(macOS) || os(Linux)

public extension BluetoothHostControllerInterface {
    
    /// LE Advertise with iBeacon
    func setLockAdvertisingData(lock: UUID, rssi: Int8, commandTimeout: HCICommandTimeout = .default) throws {
        
        do { try enableLowEnergyAdvertising(false) }
        catch HCIError.commandDisallowed { }
        
        let beacon = AppleBeacon(uuid: lock, rssi: rssi)
        let flags: GAPFlags = [.lowEnergyGeneralDiscoverableMode, .notSupportedBREDR]
        
        try iBeacon(beacon, flags: flags, interval: .min, timeout: commandTimeout)
        
        do { try enableLowEnergyAdvertising() }
        catch HCIError.commandDisallowed { }
    }
    
    /// LE Scan Response
    func setLockScanResponse(commandTimeout: HCICommandTimeout = .default) throws {
        
        do { try enableLowEnergyAdvertising(false) }
        catch HCIError.commandDisallowed { }
        
        let name: GAPCompleteLocalName = "Lock"
        let serviceUUID: GAPIncompleteListOf128BitServiceClassUUIDs = [UUID(bluetooth: LockService.uuid)]
        
        let encoder = GAPDataEncoder()
        let data = try encoder.encodeAdvertisingData(name, serviceUUID)
        
        try setLowEnergyScanResponse(data, timeout: commandTimeout)
        
        do { try enableLowEnergyAdvertising() }
        catch HCIError.commandDisallowed { }
    }
    
    /// LE Advertise with iBeacon for data changed
    func setNotificationAdvertisement(rssi: Int8, commandTimeout: HCICommandTimeout = .default) throws {
        
        do { try enableLowEnergyAdvertising(false) }
        catch HCIError.commandDisallowed { }
        
        let beacon = AppleBeacon(uuid: .lockNotificationBeacon, rssi: rssi)
        let flags: GAPFlags = [.lowEnergyGeneralDiscoverableMode, .notSupportedBREDR]
        try iBeacon(beacon, flags: flags, interval: .min, timeout: commandTimeout)
        
        do { try enableLowEnergyAdvertising() }
        catch HCIError.commandDisallowed { }
    }
}

#endif
