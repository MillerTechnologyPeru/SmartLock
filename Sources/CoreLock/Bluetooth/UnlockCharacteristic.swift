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
public struct UnlockCharacteristic: TLVCharacteristic, Codable, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "265B3EC0-044D-11E6-90F2-09AB70D5A8C7")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    /// Identifier of key making request.
    public let id: UUID
    
    /// Unlock action.
    public let action: UnlockAction
    
    /// HMAC of key and nonce, and HMAC message
    public let authentication: Authentication
    
    public init(id: UUID,
                action: UnlockAction = .default,
                authentication: Authentication) {
        
        self.id = id
        self.action = action
        self.authentication = authentication
    }
}
