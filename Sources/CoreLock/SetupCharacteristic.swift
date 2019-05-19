//
//  SetupCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth

/// Used for initial lock setup.
public struct SetupCharacteristic: TLVCharacteristic {
    
    public static let uuid = BluetoothUUID(rawValue: "129E401C-044D-11E6-8FA9-09AB70D5A8C7")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    public let encryptedData: EncryptedData
    
    public init(encryptedData: EncryptedData) {
        
        self.encryptedData = encryptedData
    }
    
    public init(request: SetupRequest, sharedSecret: KeyData) throws {
        
        let encoder = 
        let encryptedData = try EncryptedData(encrypt: request.data, with: sharedSecret)
        self.init(encryptedData: encryptedData)
    }
    
    public func decrypt(with sharedSecret: KeyData) throws -> SetupRequest {
        
        let data = try encryptedData.decrypt(with: sharedSecret)
        guard let value = SetupRequest(data: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
    
    public init?(data: Data) {
        
        guard let encryptedData = EncryptedData(data: data)
            else { return nil }
        
        self.encryptedData = encryptedData
    }
    
    public var data: Data {
        
        return encryptedData.data
    }
}

public struct SetupRequest {
    
    internal static let length = MemoryLayout<UInt128>.size + KeyData.length
    
    /// Key identifier
    public let identifier: UUID
    
    /// Key secret
    public let secret: KeyData
    
    public init(identifier: UUID = UUID(),
                secret: KeyData = KeyData()) {
        
        self.identifier = identifier
        self.secret = secret
    }
}

public extension Key {
    
    /// Initialize a new owner key from a setup request. 
    init(setup: SetupRequest) {
        
        self.init(identifier: setup.identifier,
                  name: "Owner",
                  date: Date(),
                  permission: .owner)
    }
}
