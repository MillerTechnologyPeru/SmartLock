//
//  Central.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/6/18.
//

import Foundation
import Bluetooth
import GATT

internal extension CentralProtocol {
    
    /// Connects to the device, fetches the data, performs the action, and disconnects.
    func device <T> (for peripheral: Peripheral,
                     profile: GATTProfile.Type,
                     timeout: Timeout,
                     _ action: ([Characteristic<Peripheral>]) throws -> (T)) throws -> T {
        
        // connect first
        try connect(to: peripheral, timeout: try timeout.timeRemaining())
        
        // disconnect
        defer { disconnect(peripheral: peripheral) }
        
        let foundCharacteristics = try self.profile(profile,
                                                    for: peripheral,
                                                    timeout: timeout)
        
        // perform action
        return try action(foundCharacteristics)
    }
    
    func write <T: GATTProfileCharacteristic> (_ characteristic: T,
                                               for cache: [Characteristic<Peripheral>],
                                               withResponse response: Bool = true,
                                               timeout: Timeout) throws {
        
        guard let foundCharacteristic = cache.first(where: { $0.uuid == T.uuid })
            else { throw CentralError.invalidAttribute(T.uuid) }
        
        try self.writeValue(characteristic.data,
                               for: foundCharacteristic,
                               withResponse: response,
                               timeout: try timeout.timeRemaining())
    }
    
    func read <T: GATTProfileCharacteristic> (_ characteristic: T.Type,
                                                      for cache: [Characteristic<Peripheral>],
                                                      timeout: Timeout) throws -> T {
        
        guard let foundCharacteristic = cache.first(where: { $0.uuid == T.uuid })
            else { throw CentralError.invalidAttribute(T.uuid) }
        
        let data = try self.readValue(for: foundCharacteristic,
                                         timeout: try timeout.timeRemaining())
        
        guard let value = T.init(data: data)
            else { throw GATTError.invalidData(data) }
        
        return value
    }
    
    func notify <T: GATTProfileCharacteristic> (_ characteristic: T.Type,
                                                for cache: [Characteristic<Peripheral>],
                                                timeout: Timeout,
                                                notification: ((ErrorValue<T>) -> ())?) throws {
        
        guard let foundCharacteristic = cache.first(where: { $0.uuid == T.uuid })
            else { throw CentralError.invalidAttribute(T.uuid) }
        
        let dataNotification: ((Data) -> ())?
        
        if let notification = notification {
            
            dataNotification = { (data) in
                
                let response: ErrorValue<T>
                
                if let value = T.init(data: data) {
                    
                    response = .value(value)
                    
                } else {
                    
                    response = .error(SmartLockGATTError.invalidData(data))
                }
                
                notification(response)
            }
            
        } else {
            
            dataNotification = nil
        }
        
        try notify(dataNotification, for: foundCharacteristic, timeout: try timeout.timeRemaining())
    }
    
    /// Verify a peripheral declares the GATT profile.
    func profile(_ profile: GATTProfile.Type,
                for peripheral: Peripheral,
                timeout: Timeout) throws -> [Characteristic<Peripheral>] {
        
        // group characteristics by service
        var characteristicsByService = [BluetoothUUID: [BluetoothUUID]]()
        profile.services.forEach {
            characteristicsByService[$0.uuid] = (characteristicsByService[$0.uuid] ?? []) + $0.characteristics.map { $0.uuid }
        }
        
        var results = [Characteristic<Peripheral>]()
        
        // validate required characteristics
        let foundServices = try discoverServices([], for: peripheral, timeout: try timeout.timeRemaining())
        
        for (serviceUUID, characteristics) in characteristicsByService {
            
            // validate service exists
            guard let service = foundServices.first(where: { $0.uuid == serviceUUID })
                else { throw SmartLockGATTError.serviceNotFound(serviceUUID) }
            
            // validate characteristic exists
            let foundCharacteristics = try discoverCharacteristics([], for: service, timeout: try timeout.timeRemaining())
            
            for characteristicUUID in characteristics {
                
                guard let characteristic = foundCharacteristics.first(where: { $0.uuid == characteristicUUID })
                    else { throw SmartLockGATTError.characteristicNotFound(characteristicUUID) }
                
                results.append(characteristic)
            }
        }
        
        assert(results.count == profile.characteristics.count)
        
        return results
    }
}

// MARK: - Supporting Types

/// Basic wrapper for error / value pairs.
internal enum ErrorValue <T> {
    
    case error(Error)
    case value(T)
}

// GATT timeout
internal struct Timeout {
    
    let start: Date
    
    let timeout: TimeInterval
    
    var end: Date {
        
        return start + timeout
    }
    
    init(start: Date = Date(),
         timeout: TimeInterval) {
        
        self.start = start
        self.timeout = timeout
    }
    
    @discardableResult
    func timeRemaining(for date: Date = Date()) throws -> TimeInterval {
        
        let remaining = end.timeIntervalSince(date)
        
        if remaining > 0 {
            
            return remaining
            
        } else {
            
            throw CentralError.timeout
        }
    }
}
