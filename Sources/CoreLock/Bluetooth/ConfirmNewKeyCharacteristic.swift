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
    
    public init(request: ConfirmNewKeyRequest, for key: UUID, sharedSecret: KeyData) throws {
        
        let requestData = try type(of: self).encoder.encode(request)
        self.encryptedData = try EncryptedData(encrypt: requestData, using: sharedSecret, id: .zero)
    }
    
    public func decrypt(with sharedSecret: KeyData) throws -> ConfirmNewKeyRequest {
        
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
