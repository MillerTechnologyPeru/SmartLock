//
//  ListEventsCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/31/19.
//

import Foundation
import Bluetooth

/// List events request
public struct ListEventsCharacteristic: TLVCharacteristic, Codable, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "98433693-D5BB-44A4-A929-63B453C3A8C4")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    /// Identifier of key making request.
    public let identifier: UUID
    
    /// HMAC of key and nonce, and HMAC message
    public let authentication: Authentication
    
    /// Fetch limit for events to view.
    public let fetchRequest: LockEvent.FetchRequest?
    
    public init(identifier: UUID,
                authentication: Authentication,
                fetchRequest: LockEvent.FetchRequest? = nil) {
        
        self.identifier = identifier
        self.authentication = authentication
        self.fetchRequest = fetchRequest
    }
}
