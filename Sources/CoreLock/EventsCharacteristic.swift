//
//  EventsCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/31/19.
//

import Foundation
import Bluetooth
import TLVCoding

/// Encrypted list of events.
public struct EventsCharacteristic: GATTEncryptedNotification, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "DB2E0806-C9B1-4E39-A94C-0CF9A032D483")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.notify]
    
    internal static let encoder = TLVEncoder()
    
    internal static let decoder = TLVDecoder()
    
    public let chunk: Chunk
    
    public init(chunk: Chunk) {
        self.chunk = chunk
    }
}

public extension EventsCharacteristic {
    
    static func from(chunks: [Chunk]) throws -> EncryptedData {
        
        let data = Data(chunks: chunks)
        guard let value = try? decoder.decode(EncryptedData.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
    
    static func from(chunks: [Chunk], secret: KeyData) throws -> EventListNotification {
        
        let encryptedData = try from(chunks: chunks)
        let data = try encryptedData.decrypt(with: secret)
        guard let value = try? decoder.decode(EventListNotification.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
    
    static func from(_ value: EncryptedData, maximumUpdateValueLength: Int) throws -> [EventsCharacteristic] {
        
        let data = try encoder.encode(value)
        let chunks = Chunk.from(data, maximumUpdateValueLength: maximumUpdateValueLength)
        return chunks.map { .init(chunk: $0) }
    }
    
    static func from(_ value: EventListNotification,
                     sharedSecret: KeyData,
                     maximumUpdateValueLength: Int) throws -> [EventsCharacteristic] {
        
        let data = try encoder.encode(value)
        let encryptedData = try EncryptedData(encrypt: data, with: sharedSecret)
        return try from(encryptedData, maximumUpdateValueLength: maximumUpdateValueLength)
    }
}

public typealias EventsList = [LockEvent]

public struct EventListNotification: Codable, Equatable, GATTEncryptedNotificationValue {
    
    public var event: LockEvent?
    
    public var isLast: Bool
}

public extension EventListNotification {
    
    static func from(list: EventsList) -> [EventListNotification] {
        
        guard list.isEmpty == false
            else { return [EventListNotification(event: nil, isLast: true) ] }
        var notifications = list.map { EventListNotification(event: $0, isLast: false) }
        assert(notifications.isEmpty == false)
        notifications[notifications.count - 1].isLast = true
        return notifications
    }
}
