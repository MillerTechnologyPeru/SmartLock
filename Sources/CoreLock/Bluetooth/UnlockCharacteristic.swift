//
//  UnlockCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth
import GATT

/// Used to unlock door.
public struct UnlockCharacteristic: TLVEncryptedCharacteristic, Codable, Equatable {
    
    public static var uuid: BluetoothUUID { BluetoothUUID(rawValue: "265B3EC0-044D-11E6-90F2-09AB70D5A8C7")! }
    
    public static var service: GATTProfileService.Type { LockService.self }
    
    public static var properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> { [.write] }
    
    public let encryptedData: EncryptedData
    
    public init(encryptedData: EncryptedData) {
        self.encryptedData = encryptedData
    }
    
    public init(request: UnlockRequest, using key: KeyData, id: UUID) throws {
        
        let requestData = try type(of: self).encoder.encode(request)
        self.encryptedData = try EncryptedData(encrypt: requestData, using: key, id: id)
    }
    
    public func decrypt(with sharedSecret: KeyData) throws -> UnlockRequest {
        
        let data = try encryptedData.decrypt(using: sharedSecret)
        guard let value = try? type(of: self).decoder.decode(UnlockRequest.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
}

// MARK: - Supporting Types

public struct UnlockRequest: Equatable, Codable {
    
    /// Unlock action.
    public let action: UnlockAction
    
    public init(action: UnlockAction = .default) {
        self.action = action
    }
}

// MARK: - Central

public extension CentralManager {
    
    /// Unlock action.
    func unlock(
        _ action: UnlockAction = .default,
        using key: KeyCredentials,
        for peripheral: Peripheral
    ) async throws {
        try await connection(for: peripheral) {
            try await $0.unlock(action, using: key)
        }
    }
}

public extension GATTConnection {
    
    /// Unlock action.
    func unlock(
        _ action: UnlockAction = .default,
        using key: KeyCredentials
    ) async throws {
        let characteristicValue = try UnlockCharacteristic(
            request: UnlockRequest(action: action),
            using: key.secret,
            id: key.id
        )
        try await write(characteristicValue, response: true)
    }
}
