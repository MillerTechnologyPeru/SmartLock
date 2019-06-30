//
//  KeysCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 6/29/19.
//

import Foundation
import Bluetooth

/// Encrypted list of keys.
public struct KeysCharacteristic: GATTProfileCharacteristic, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "6AFA0D36-4567-4486-BEE5-E14A622B805F")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.notify]
    
    public let chunk: Chunk
    
    public init?(data: Data) {
        
        guard let chunk = Chunk(data: data)
            else { return nil }
        
        self.chunk = chunk
    }
    
    public var data: Data {
        
        return chunk.data
    }
}

public struct KeysList: Codable, Equatable {
    
    public let keys: [Key]
    
    public let newKeys: [NewKey]
}

public extension KeysList {
    
    struct Key: Codable, Equatable {
        
        /// The unique identifier of the key.
        public let identifier: UUID
        
        /// The name of the key.
        public let name: String
        
        /// Date key was created.
        public let created: Date
        
        /// Key's permissions.
        public let permission: Permission
    }
    
    struct NewKey: Codable, Equatable {
        
        /// The unique identifier of the key.
        public let identifier: UUID
        
        /// The name of the key.
        public let name: String
        
        /// Date key was created.
        public let created: Date
        
        /// Key's permissions.
        public let permission: Permission
        
        /// Date new key invitation expires.
        public let expiration: Date
    }
}
