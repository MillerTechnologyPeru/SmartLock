//
//  ListKeysCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 6/29/19.
//

import Foundation
import Bluetooth
import GATT

/// List keys request
public struct ListKeysCharacteristic: TLVCharacteristic, Codable, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "35233251-5733-48DD-A8CE-0C2B3B4B6949")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    /// Identifier of key making request.
    public let id: UUID
    
    /// HMAC of key and nonce, and HMAC message
    public let authentication: Authentication
    
    public init(id: UUID,
                authentication: Authentication) {
        
        self.id = id
        self.authentication = authentication
    }
}
