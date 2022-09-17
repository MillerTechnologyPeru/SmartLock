//
//  RemoveKeyCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 6/30/19.
//

import Foundation
import Bluetooth
import GATT

/// Remove the specified key. 
public struct RemoveKeyCharacteristic: TLVEncryptedCharacteristic, Codable, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "2DB6C1AF-8FFD-4F7F-9B5A-F0BC9662F9BB")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    public let encryptedData: EncryptedData
    
    public init(encryptedData: EncryptedData) {
        self.encryptedData = encryptedData
    }
    
    public init(request: RemoveKeyRequest, using key: KeyData, id: UUID) throws {
        
        let requestData = try type(of: self).encoder.encode(request)
        self.encryptedData = try EncryptedData(encrypt: requestData, using: key, id: id)
    }
    
    public func decrypt(using key: KeyData) throws -> RemoveKeyRequest {
        
        let data = try encryptedData.decrypt(using: key)
        guard let value = try? type(of: self).decoder.decode(RemoveKeyRequest.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
}

// MARK: - Supporting Types

public struct RemoveKeyRequest: Equatable, Codable {
    
    /// Key to remove.
    public let id: UUID
    
    /// Type of key
    public let type: KeyType
    
    public init(id: UUID,
                type: KeyType) {
        
        self.id = id
        self.type = type
    }
}
