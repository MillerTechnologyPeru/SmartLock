//
//  SetupCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth
import GATT

/// Used for initial lock setup.
public struct SetupCharacteristic: TLVCharacteristic, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "129E401C-044D-11E6-8FA9-09AB70D5A8C7")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    public let encryptedData: EncryptedData
    
    public init(request: SetupRequest, sharedSecret: KeyData) throws {
        
        let requestData = try type(of: self).encoder.encode(request)
        self.encryptedData = try EncryptedData(encrypt: requestData, with: sharedSecret)
    }
    
    public func decrypt(with sharedSecret: KeyData) throws -> SetupRequest {
        
        let data = try encryptedData.decrypt(with: sharedSecret)
        guard let value = try? type(of: self).decoder.decode(SetupRequest.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
}

// MARK: - Codable

extension SetupCharacteristic: Codable {
    
    public init(from decoder: Decoder) throws {
        self.encryptedData = try EncryptedData(from: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        try self.encryptedData.encode(to: encoder)
    }
}

// MARK: - Supporting Types

public struct SetupRequest: Equatable, Codable {
    
    /// Key identifier
    public let id: UUID
    
    /// Key secret
    public let secret: KeyData
    
    public init(id: UUID = UUID(),
                secret: KeyData = KeyData()) {
        
        self.id = id
        self.secret = secret
    }
}

public extension Key {
    
    /// Initialize a new owner key from a setup request. 
    init(setup: SetupRequest) {
        
        self.init(
            id: setup.id,
            name: "Owner",
            created: Date(),
            permission: .owner
        )
    }
}
