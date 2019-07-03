//
//  RemoveKeyCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 6/30/19.
//

import Foundation
import Bluetooth

/// Remove the specified key. 
public struct RemoveKeyCharacteristic: TLVCharacteristic, Codable, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "2DB6C1AF-8FFD-4F7F-9B5A-F0BC9662F9BB")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    /// Identifier of key making request.
    public let identifier: UUID
    
    /// Key to remove.
    public let key: UUID
    
    /// Type of key
    public let type: KeyType
    
    /// HMAC of key and nonce, and HMAC message
    public let authentication: Authentication
    
    public init(identifier: UUID,
                key: UUID,
                type: KeyType,
                authentication: Authentication) {
        
        self.identifier = identifier
        self.key = key
        self.type = type
        self.authentication = authentication
    }
}
