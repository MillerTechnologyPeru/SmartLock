//
//  DeviceManager.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/8/18.
//

import Foundation
import Bluetooth
import GATT

/// SmartLock GATT Central client.
public final class SmartLockManager <Central: CentralProtocol> {
    
    public typealias Peripheral = Central.Peripheral
    
    public typealias Advertisement = Central.Advertisement
    
    // MARK: - Initialization
    
    public init(central: Central) {
        
        self.central = central
    }
    
    // MARK: - Properties
    
    /// GATT Central Manager.
    public let central: Central
    
    /// The log message handler.
    public var log: ((String) -> ())? {
        
        get { return central.log }
        
        set { central.log = newValue }
    }
    
    /// Scans for nearby devices.
    ///
    /// - Parameter duration: The duration of the scan.
    ///
    /// - Parameter event: Callback for a found device.
    public func scan(duration: TimeInterval,
                     filterDuplicates: Bool = true,
                     event: @escaping ((LockPeripheral<Central>) -> ())) throws {
        
        let start = Date()
        
        let end = start + duration
        
        try self.scan(filterDuplicates: filterDuplicates, scanMore: { Date() < end  }, event: event)
    }
    
    /// Scans for nearby devices.
    ///
    /// - Parameter event: Callback for a found device.
    ///
    /// - Parameter scanMore: Callback for determining whether the manager
    /// should continue scanning for more devices.
    public func scan(filterDuplicates: Bool = true,
                     scanMore: () -> (Bool),
                     event: @escaping ((LockPeripheral<Central>) -> ())) throws {
        
        var foundLocks = [Peripheral: LockPeripheral<Central>]()
        
        try self.central.scan(filterDuplicates: filterDuplicates, shouldContinueScanning: scanMore) { (scanData) in
            
            // filter peripheral
            guard let lock = LockPeripheral<Central>(scanData)
                else { return }
            
            foundLocks[scanData.peripheral] = lock
            
            event(lock)
        }
        
        if foundLocks.isEmpty == false {
            log?("Found \(foundLocks.count) Locks")
        }
    }
    
    public func readInformation(for peripheral: Peripheral,
                                timeout: TimeInterval = .gattDefaultTimeout) throws -> InformationCharacteristic {
        
        let timeout = Timeout(timeout: timeout)
        
        return try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            
            return try self.readInformation(cache: cache, timeout: timeout)
        }
    }
    
    internal func readInformation(cache: GATTConnectionCache<Peripheral>,
                                  timeout: Timeout) throws -> InformationCharacteristic {
        
        return try central.read(InformationCharacteristic.self, for: cache, timeout: timeout)
    }
    
    /// Setup a lock.
    public func setup(peripheral: Peripheral,
                      with request: SetupRequest,
                      sharedSecret: KeyData,
                      timeout: TimeInterval = .gattDefaultTimeout) throws -> InformationCharacteristic {
        
        let timeout = Timeout(timeout: timeout)
        
        return try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            
            // encrypt owner key data
            let characteristicValue = try SetupCharacteristic(request: request,
                                                              sharedSecret: sharedSecret)
            
            // write setup characteristic
            try self.central.write(characteristicValue, for: cache, timeout: timeout)
            
            // read information
            let information = try self.readInformation(cache: cache, timeout: timeout)
            
            guard information.status == .unlock
                else { throw GATTError.couldNotComplete }
            
            return information
        }
    }
    
    /// Unlock action.
    public func unlock(key: (identifier: UUID, secret: KeyData),
                       action: UnlockAction = .default,
                       peripheral: Peripheral,
                       timeout: TimeInterval = .gattDefaultTimeout) throws {
        
        let timeout = Timeout(timeout: timeout)
        
        return try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            
            let characteristicValue = UnlockCharacteristic(identifier: key.identifier,
                                                           action: action,
                                                           authentication: Authentication(key: key.secret))
            
            // Write unlock data to characteristic
            try self.central.write(characteristicValue, for: cache, timeout: timeout)
        }
    }
}

public struct LockPeripheral <Central: CentralProtocol> {
    
    /// Identifier of the lock
    public var identifer: UUID {
        
        return beacon.uuid
    }
    
    /// Advertised iBeacon
    public let beacon: AppleBeacon
    
    /// Scan Data
    public let scanData: ScanData<Central.Peripheral, Central.Advertisement>
    
    /// Initialize from scan data.
    internal init?(_ scanData: ScanData<Central.Peripheral, Central.Advertisement>) {
        
        // filter peripheral
        guard scanData.advertisementData.serviceUUIDs.contains(LockService.uuid)
            else { return nil }
        
        // get UUID from iBeacon
        guard let data = scanData.advertisementData.manufacturerData,
            let manufacturerData = GAPManufacturerSpecificData(data: data),
            let beacon = AppleBeacon(manufactererData: manufacturerData)
            else { return nil }
        
        self.scanData = scanData
        self.beacon = beacon
    }
}
