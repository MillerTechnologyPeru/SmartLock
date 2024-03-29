//
//  CreateNewKeyCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 6/29/19.
//

import Foundation
import Bluetooth
import GATT

/// Used to create a new key.
public struct CreateNewKeyCharacteristic: TLVEncryptedCharacteristic, Codable, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "1C9AC449-39DC-4E4D-AE7C-FAF51D35CD7D")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    /// Encrypted payload.
    public let encryptedData: EncryptedData
    
    public init(encryptedData: EncryptedData) {
        self.encryptedData = encryptedData
    }
    
    public init(request: CreateNewKeyRequest, using key: KeyData, id: UUID) throws {
        
        let requestData = try type(of: self).encoder.encode(request)
        self.encryptedData = try EncryptedData(encrypt: requestData, using: key, id: id)
    }
    
    public  func decrypt(using sharedSecret: KeyData) throws -> CreateNewKeyRequest {
        
        let data = try encryptedData.decrypt(using: sharedSecret)
        guard let value = try? type(of: self).decoder.decode(CreateNewKeyRequest.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
}

// MARK: - Supporting Types

public struct CreateNewKeyRequest: Equatable, Codable {
    
    /// New Key identifier
    public let id: UUID
    
    /// The name of the new key.
    public let name: String
    
    /// The permission of the new key.
    public let permission: Permission
    
    /// Expiration of temporary new key request.
    public let expiration: Date
    
    /// Shared secret for encrypting the new key.
    public let secret: KeyData
}

public extension CreateNewKeyRequest {
    
    init(key: NewKey, secret: KeyData) {
        
        self.id = key.id
        self.name = key.name
        self.permission = key.permission
        self.expiration = key.expiration
        self.secret = secret
    }
}

public extension NewKey {
    
    init(request: CreateNewKeyRequest, created: Date = Date()) {
        
        self.id = request.id
        self.name = request.name
        self.permission = request.permission
        self.expiration = request.expiration
        self.created = created
    }
}

// MARK: - Central

public extension CentralManager {
    
    /// Create new key.
    func createKey(
        _ newKey: CreateNewKeyRequest,
        using key: KeyCredentials,
        for peripheral: Peripheral
    ) async throws {
        try await connection(for: peripheral) {
            try await $0.createKey(newKey, using: key)
        }
    }
}

public extension GATTConnection {
    
    /// Create new key.
    func createKey(
        _ newKey: CreateNewKeyRequest,
        using key: KeyCredentials
    ) async throws {
        let characteristicValue = try CreateNewKeyCharacteristic(
            request: newKey,
            using: key.secret,
            id: key.id
        )
        try await write(characteristicValue, response: true)
    }
}
