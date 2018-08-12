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
                     event: ((Peripheral) -> ())? = nil) throws {
        
        let start = Date()
        
        let end = start + duration
        
        try self.scan(filterDuplicates: filterDuplicates, event: event, scanMore: { Date() < end  })
    }
    
    /// Scans for nearby devices.
    ///
    /// - Parameter event: Callback for a found device.
    ///
    /// - Parameter scanMore: Callback for determining whether the manager
    /// should continue scanning for more devices.
    public func scan(filterDuplicates: Bool = true,
                     event: ((Peripheral) -> ())? = nil,
                     scanMore: () -> (Bool)) throws {
        
        var foundPeripherals = Set<Peripheral>()
        
        var foundLocks = Set<Peripheral>()
        
        try self.central.scan(filterDuplicates: filterDuplicates, shouldContinueScanning: scanMore) { (scanData) in
            
            foundPeripherals.insert(scanData.peripheral)
            
            // filter peripheral
            guard scanData.advertisementData.serviceUUIDs.contains(LockService.uuid)
                else { return }
            
            foundLocks.insert(scanData.peripheral)
            
            event?(scanData.peripheral)
        }
        
        let foundDevicesCount = foundLocks.count
        
        if foundDevicesCount > 0 { self.log?("Found \(foundPeripherals.count) peripherals (\(foundLocks.count) Locks)") }
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
        
        // encrypt owner key data
        let characteristicValue = try SetupCharacteristic(request: request,
                                                          sharedSecret: sharedSecret)
        
        let timeout = Timeout(timeout: timeout)
        
        return try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            
            // write setup characteristic
            try self.central.write(characteristicValue, for: cache, timeout: timeout)
            
            // read information
            let information = try self.readInformation(cache: cache, timeout: timeout)
            
            return information
        }
    }
    
    /// Unlock action.
    public func unlock(key: (identifier: UUID, secret: KeyData),
                       action: UnlockAction = .default,
                       peripheral: Peripheral,
                       timeout: TimeInterval = .gattDefaultTimeout) throws {
        
        let characteristicValue = UnlockCharacteristic(identifier: key.identifier,
                                                       action: action,
                                                       authentication: Authentication(key: key.secret))
        
        let timeout = Timeout(timeout: timeout)
        
        return try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            
            // Write unlock data to characteristic
            try self.central.write(characteristicValue, for: cache, timeout: timeout)
        }
    }
    
    // MARK: - Private Methods
    
    
}

/// Lock Peripheral
public struct LockPeripheral <Peripheral: Peer> {
    
    public let peripheral: Peripheral
}
