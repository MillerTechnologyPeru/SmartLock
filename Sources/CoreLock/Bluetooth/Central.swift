//
//  Central.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/6/18.
//

import Foundation
import Bluetooth
import GATT

public extension CentralManager {
    
    func connection<T>(
        for peripheral: Peripheral,
        _ connection: (GATTConnection<Self>
        ) async throws -> (T)) async throws -> T {
                
        // connect first
        try await self.connect(to: peripheral)
        
        do {
            // cache MTU
            let maximumTransmissionUnit = try await self.maximumTransmissionUnit(for: peripheral)
            
            // get characteristics by UUID
            let characteristics = try await self.characteristics(for: peripheral)
            
            let cache = GATTConnection(
                central: self,
                maximumTransmissionUnit: maximumTransmissionUnit,
                characteristics: characteristics
            )
            
            // perform action
            let value = try await connection(cache)
            // disconnect
            await self.disconnect(peripheral)
            return value
        }
        catch {
            await self.disconnect(peripheral)
            throw error
        }
    }
}

public struct GATTConnection <Central: CentralManager> {
    
    internal let central: Central
        
    public let maximumTransmissionUnit: GATT.MaximumTransmissionUnit
    
    internal let characteristics: [BluetoothUUID: [Characteristic<Central.Peripheral, Central.AttributeID>]]
}

public extension GATTConnection {
    
    subscript (type: GATTProfileCharacteristic.Type) -> Characteristic<Central.Peripheral, Central.AttributeID>? {
        return try? characteristic(for: type)
    }
    
    func characteristic(for type: GATTProfileCharacteristic.Type) throws -> Characteristic<Central.Peripheral, Central.AttributeID> {
        guard let cache = self.characteristics[type.service.uuid]
            else { throw GATTError.serviceNotFound(type.service.uuid) }
        guard let foundCharacteristic = cache.first(where: { $0.uuid == type.uuid })
            else { throw GATTError.characteristicNotFound(type.uuid) }
        return foundCharacteristic
    }
    
    func read<T: GATTProfileCharacteristic>(_ type: T.Type) async throws -> T {
        let characteristics = self.characteristics[T.service.uuid] ?? []
        return try await central.read(type, for: characteristics)
    }
    
    func write<T: GATTProfileCharacteristic>(_ value: T, response: Bool = true) async throws {
        let characteristics = self.characteristics[T.service.uuid] ?? []
        try await central.write(value, for: characteristics, response: response)
    }
    
    func notify<T: GATTProfileCharacteristic>(
        _ type: T.Type
    ) async throws -> AsyncIndefiniteStream<T> {
        let characteristics = self.characteristics[T.service.uuid] ?? []
        return try await central.notify(type, for: characteristics)
    }
}

internal extension CentralManager {
    
    /// Connects to the device, fetches the data, and performs the action, and disconnects.
    func connection<T>(
        for peripheral: Peripheral,
        characteristics: [GATTProfileCharacteristic.Type],
        _ action: ([Characteristic<Peripheral, AttributeID>]
        ) throws -> (T)) async throws -> T {
                
        // connect first
        try await self.connect(to: peripheral)
        
        do {
            // get characteristics by UUID
            let foundCharacteristics = try await self.characteristics(
                characteristics,
                for: peripheral
            )
            
            // perform action
            let value = try action(foundCharacteristics)
            // disconnect
            await self.disconnect(peripheral)
            return value
        }
        catch {
            await self.disconnect(peripheral)
            throw error
        }
    }
    
    /// Verify a peripheral declares the GATT profile.
    func characteristics(
        _ characteristics: [GATTProfileCharacteristic.Type],
        for peripheral: Peripheral
    ) async throws -> [Characteristic<Peripheral, AttributeID>] {
                
        // group characteristics by service
        var characteristicsByService = [BluetoothUUID: [BluetoothUUID]]()
        characteristics.forEach {
            characteristicsByService[$0.service.uuid] = (characteristicsByService[$0.service.uuid] ?? []) + [$0.uuid]
        }
        
        var results = [Characteristic<Peripheral, AttributeID>]()
        
        // validate required characteristics
        let foundServices = try await discoverServices([], for: peripheral)
        
        for (serviceUUID, characteristics) in characteristicsByService {
            
            // validate service exists
            guard let service = foundServices.first(where: { $0.uuid == serviceUUID })
                else { throw GATTError.serviceNotFound(serviceUUID) }
            
            // validate characteristic exists
            let foundCharacteristics = try await discoverCharacteristics([], for: service)
            
            for characteristicUUID in characteristics {
                
                guard foundCharacteristics.contains(where: { $0.uuid == characteristicUUID })
                    else { throw GATTError.characteristicNotFound(characteristicUUID) }
            }
            
            results += foundCharacteristics
        }
        
        return results
    }
    
    /// Fetch all characteristics for all services.
    func characteristics(
        for peripheral: Peripheral
    ) async throws -> [BluetoothUUID: [Characteristic<Peripheral, AttributeID>]] {
        
        var characteristicsByService = [BluetoothUUID: [Characteristic<Peripheral, AttributeID>]]()
        let foundServices = try await discoverServices([], for: peripheral)
        for service in foundServices {
            let foundCharacteristics = try await discoverCharacteristics([], for: service)
            for characteristic in foundCharacteristics {
                characteristicsByService[service.uuid, default: []]
                    .append(characteristic)
            }
        }
        return characteristicsByService
    }
    
    func write <T: GATTProfileCharacteristic> (
        _ characteristic: T,
        for cache: [Characteristic<Peripheral, AttributeID>],
        response: Bool
    ) async throws {
        
        guard let foundCharacteristic = cache.first(where: { $0.uuid == T.uuid })
            else { throw CentralError.invalidAttribute(T.uuid) }
        
        try await self.writeValue(
            characteristic.data,
            for: foundCharacteristic,
            withResponse: response
        )
    }
    
    func read<T: GATTProfileCharacteristic>(
        _ characteristic: T.Type,
        for cache: [Characteristic<Peripheral, AttributeID>]
    ) async throws -> T {
        
        guard let foundCharacteristic = cache.first(where: { $0.uuid == T.uuid })
            else { throw CentralError.invalidAttribute(T.uuid) }
        
        let data = try await self.readValue(for: foundCharacteristic)
        
        guard let value = T.init(data: data)
            else { throw GATTError.invalidData(data) }
        
        return value
    }
    
    func notify<T: GATTProfileCharacteristic>(
        _ characteristic: T.Type,
        for cache: [Characteristic<Peripheral, AttributeID>]
    ) async throws -> AsyncIndefiniteStream<T> {
        
        guard let foundCharacteristic = cache.first(where: { $0.uuid == T.uuid })
            else { throw CentralError.invalidAttribute(T.uuid) }
        
        let stream = try await self.notify(for: foundCharacteristic)
        
        return AsyncIndefiniteStream { continuation in
            for try await data in stream {
                guard let value = T.init(data: data) else {
                    throw GATTError.invalidData(data)
                }
                continuation(value)
            }
        }
    }
}
