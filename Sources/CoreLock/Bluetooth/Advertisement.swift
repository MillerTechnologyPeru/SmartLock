//
//  Advertisement.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

#if os(macOS) || os(Linux)

import Foundation
import Bluetooth
import BluetoothHCI
import BluetoothGAP

public extension BluetoothHostControllerInterface {
    
    /// LE Advertise with iBeacon
    func setLockAdvertisingData(lock: UUID, rssi: Int8) async throws {
        
        do { try await enableLowEnergyAdvertising(false) }
        catch HCIError.commandDisallowed { }
        
        let beacon = AppleBeacon(uuid: lock, rssi: rssi)
        let flags: GAPFlags = [.lowEnergyGeneralDiscoverableMode, .notSupportedBREDR]
        
        try await iBeacon(beacon, flags: flags, interval: .min)
        
        do { try await enableLowEnergyAdvertising() }
        catch HCIError.commandDisallowed { }
    }
    
    /// LE Scan Response
    func setLockScanResponse() async throws {
        
        do { try await enableLowEnergyAdvertising(false) }
        catch HCIError.commandDisallowed { }
        
        let name: GAPCompleteLocalName = "Lock"
        let serviceUUID: GAPIncompleteListOf128BitServiceClassUUIDs = [UUID(bluetooth: LockService.uuid)]
        
        let encoder = GAPDataEncoder()
        let data = try encoder.encodeAdvertisingData(name, serviceUUID)
        
        try await setLowEnergyScanResponse(data)
        
        do { try await enableLowEnergyAdvertising() }
        catch HCIError.commandDisallowed { }
    }
    
    /// LE Advertise with iBeacon for data changed
    func setNotificationAdvertisement(rssi: Int8) async throws {
        
        do { try await enableLowEnergyAdvertising(false) }
        catch HCIError.commandDisallowed { }
        
        let beacon = AppleBeacon(uuid: .lockNotificationBeacon, rssi: rssi)
        let flags: GAPFlags = [.lowEnergyGeneralDiscoverableMode, .notSupportedBREDR]
        try await iBeacon(beacon, flags: flags, interval: .min)
        
        do { try await enableLowEnergyAdvertising() }
        catch HCIError.commandDisallowed { }
    }
}

#endif
