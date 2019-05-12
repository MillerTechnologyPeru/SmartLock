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
public final class LockManager <Central: CentralProtocol> {
    
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
    public var log: ((String) -> ())?
    
    /// Scans for nearby devices.
    ///
    /// - Parameter duration: The duration of the scan.
    ///
    /// - Parameter event: Callback for a found device.
    public func scan(duration: TimeInterval,
                     filterDuplicates: Bool = false,
                     event: @escaping ((LockPeripheral<Central>) -> ())) throws {
        
        try central.scan(duration: duration, filterDuplicates: filterDuplicates) { (scanData) in
            
            // filter peripheral
            guard let lock = LockPeripheral<Central>(scanData)
                else { return }
            
            event(lock)
        }
    }
    
    /// Scans for nearby devices.
    ///
    /// - Parameter event: Callback for a found device.
    ///
    /// - Parameter scanMore: Callback for determining whether the manager
    /// should continue scanning for more devices.
    public func scan(filterDuplicates: Bool = false,
                     event: @escaping ((LockPeripheral<Central>) -> ())) throws {
        
        try self.central.scan(filterDuplicates: filterDuplicates) { (scanData) in
            
            // filter peripheral
            guard let lock = LockPeripheral<Central>(scanData)
                else { return }
            
            event(lock)
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
    
    /// Scan Data
    public let scanData: ScanData<Central.Peripheral, Central.Advertisement>
    
    /// Initialize from scan data.
    internal init?(_ scanData: ScanData<Central.Peripheral, Central.Advertisement>) {
        
        // filter peripheral
        guard let serviceUUIDs = scanData.advertisementData.serviceUUIDs, serviceUUIDs.contains(LockService.uuid)
            else { return nil }
        
        self.scanData = scanData
    }
}
