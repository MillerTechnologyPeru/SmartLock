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
        
        try self.central.scan(filterDuplicates: filterDuplicates, shouldContinueScanning: scanMore) { [unowned self] (scanData) in
            
            foundPeripherals.insert(scanData.peripheral)
            
            scanData.advertisementData
            
            // filter peripheral
            //guard let foundDevice = self.found(peripheral: scanData)
            //    else { return }
            
            event?(scanData.peripheral)
        }
        
        let foundDevicesCount = foundLocks.count
        
        if foundDevicesCount > 0 { self.log?("Found \(foundPeripherals.count) peripherals (\(foundLocks.count) Locks)") }
    }
    
    // MARK: - Private Methods
    
    
}

/// Lock Peripheral
public struct LockPeripheral <Peripheral: Peer> {
    
    public let peripheral: Peripheral
}
