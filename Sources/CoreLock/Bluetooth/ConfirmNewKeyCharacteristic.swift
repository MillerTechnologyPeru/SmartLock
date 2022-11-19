//
//  ConfirmNewKeyCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 6/29/19.
//

import Foundation
import Bluetooth
import GATT

/// Used to complete new key creation.
public struct ConfirmNewKeyCharacteristic: TLVEncryptedCharacteristic, Codable, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "35FD373F-241C-4725-A8A6-C644AADB9A1A")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    /// Encrypted payload.
    public let encryptedData: EncryptedData
    
    public init(encryptedData: EncryptedData) {
        self.encryptedData = encryptedData
    }
    
    public init(request: ConfirmNewKeyRequest, using sharedSecret: KeyData, id: UUID) throws {
        
        let requestData = try type(of: self).encoder.encode(request)
        self.encryptedData = try EncryptedData(encrypt: requestData, using: sharedSecret, id: id)
    }
    
    public func decrypt(using sharedSecret: KeyData) throws -> ConfirmNewKeyRequest {
        
        let data = try encryptedData.decrypt(using: sharedSecret)
        guard let value = try? type(of: self).decoder.decode(ConfirmNewKeyRequest.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
}

// MARK: - Supporting Types

public struct ConfirmNewKeyRequest: Equatable, Codable {
    
    /// New key private key data.
    public let secret: KeyData
    
    public init(secret: KeyData) {
        self.secret = secret
    }
}

// MARK: - Central

public extension CentralManager {
    
    /// Confirm new key.
    func confirmKey(
        _ confirmation: ConfirmNewKeyRequest,
        using key: KeyCredentials,
        for peripheral: Peripheral
    ) async throws {
        try await connection(for: peripheral) {
            try await $0.confirmKey(confirmation, using: key)
        }
    }
}

public extension GATTConnection {
    
    /// Confirm new key.
    func confirmKey(
        _ confirmation: ConfirmNewKeyRequest,
        using key: KeyCredentials
    ) async throws {
        let characteristicValue = try ConfirmNewKeyCharacteristic(
            request: confirmation,
            using: key.secret,
            id: key.id
        )
        try await write(characteristicValue, response: true)
    }
}
