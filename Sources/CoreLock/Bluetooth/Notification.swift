//
//  Notification.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 9/1/19.
//

import Foundation
import Bluetooth
import GATT

public protocol GATTEncryptedNotification: GATTProfileCharacteristic {
    
    associatedtype Notification: GATTEncryptedNotificationValue
    
    var chunk: Chunk { get }
    
    init(chunk: Chunk)
    
    static func from(chunks: [Chunk]) throws -> EncryptedData
    
    static func from(chunks: [Chunk], using key: KeyData) throws -> Notification
    
    static func from(_ value: EncryptedData, maximumUpdateValueLength: Int) throws -> [Self]
    
    static func from(_ value: Notification, id: UUID, key: KeyData, maximumUpdateValueLength: Int) throws -> [Self]
}

public protocol GATTEncryptedNotificationValue {
    
    var isLast: Bool { get }
}

public extension GATTEncryptedNotification {
    
    init?(data: Data) {
        guard let chunk = Chunk(data: data)
            else { return nil }
        
        self.init(chunk: chunk)
    }
    
    var data: Data {
        return chunk.data
    }
}
