//
//  KeysCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 6/29/19.
//

import Foundation
import Bluetooth
import TLVCoding

/// Encrypted list of keys.
public struct KeysCharacteristic: GATTEncryptedNotification, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "6AFA0D36-4567-4486-BEE5-E14A622B805F")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.notify]
    
    internal static let encoder = TLVEncoder()
    
    internal static let decoder = TLVDecoder()
    
    public let chunk: Chunk
    
    public init(chunk: Chunk) {
        self.chunk = chunk
    }
}

public extension KeysCharacteristic {
    
    static func from(chunks: [Chunk]) throws -> EncryptedData {
        
        let data = Data(chunks: chunks)
        guard let value = try? decoder.decode(EncryptedData.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
    
    static func from(chunks: [Chunk], secret: KeyData) throws -> KeyListNotification {
        
        let encryptedData = try from(chunks: chunks)
        let data = try encryptedData.decrypt(with: secret)
        guard let value = try? decoder.decode(KeyListNotification.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
    
    static func from(_ value: EncryptedData, maximumUpdateValueLength: Int) throws -> [KeysCharacteristic] {
        
        let data = try encoder.encode(value)
        let chunks = Chunk.from(data, maximumUpdateValueLength: maximumUpdateValueLength)
        return chunks.map { KeysCharacteristic(chunk: $0) }
    }
    
    static func from(_ value: KeyListNotification,
                     sharedSecret: KeyData,
                     maximumUpdateValueLength: Int) throws -> [KeysCharacteristic] {
        
        let data = try encoder.encode(value)
        let encryptedData = try EncryptedData(encrypt: data, with: sharedSecret)
        return try from(encryptedData, maximumUpdateValueLength: maximumUpdateValueLength)
    }
}

public struct KeysList: Codable, Equatable {
    
    public var keys: [Key]
    
    public var newKeys: [NewKey]
    
    public init(keys: [Key] = [], newKeys: [NewKey] = []) {
        
        self.keys = keys
        self.newKeys = newKeys
    }
}

public extension KeysList {
    
    var count: Int {
        return keys.count + newKeys.count
    }
    
    var isEmpty: Bool {
        return keys.isEmpty && newKeys.isEmpty
    }
    
    mutating func remove(_ identifier: UUID, type: KeyType = .key) {
        
        switch type {
        case .key:
            keys.removeAll(where: { $0.identifier == identifier })
        case .newKey:
            newKeys.removeAll(where: { $0.identifier == identifier })
        }
    }
}

internal extension KeysList {
    
    mutating func append(_ newValue: KeyListNotification.KeyValue) {
        switch newValue {
        case let .key(key):
            keys.append(key)
        case let .newKey(newKey):
            newKeys.append(newKey)
        }
    }
}

public struct KeyListNotification: Codable, Equatable, GATTEncryptedNotificationValue {
    
    public var key: KeyValue
    
    public var isLast: Bool
}


public extension KeyListNotification {
    
    static func from(list: KeysList) -> [KeyListNotification] {
        
        guard list.isEmpty == false else { return [] }
        
        var notifications = [KeyListNotification]()
        notifications.reserveCapacity(list.count)
        
        list.keys.forEach { notifications.append(.init(key: .key($0), isLast: false)) }
        list.newKeys.forEach { notifications.append(.init(key: .newKey($0), isLast: false)) }
        
        assert(notifications.count == list.count)
        assert(notifications.isEmpty == false)
        notifications[notifications.count - 1].isLast = true
        
        return notifications
    }
}

public extension KeyListNotification {
    
    enum KeyValue: Equatable {
        
        case key(Key)
        case newKey(NewKey)
        
        public var identifier: UUID {
            switch self {
            case let .key(key):
                return key.identifier
            case let .newKey(newKey):
                return newKey.identifier
            }
        }
    }
}

extension KeyListNotification.KeyValue: Codable {
    
    private enum CodingKeys: UInt8, TLVCodingKey, CaseIterable {
        
        case type = 0x00
        case key = 0x01
        
        var stringValue: String {
            switch self {
            case .type: return "type"
            case .key: return "key"
            }
        }
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(KeyType.self, forKey: .type)
        switch type {
        case .key:
            let key = try container.decode(Key.self, forKey: .key)
            self = .key(key)
        case .newKey:
            let newKey = try container.decode(NewKey.self, forKey: .key)
            self = .newKey(newKey)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .key(key):
            try container.encode(KeyType.key, forKey: .type)
            try container.encode(key, forKey: .key)
        case let .newKey(newKey):
            try container.encode(KeyType.newKey, forKey: .type)
            try container.encode(newKey, forKey: .key)
        }
    }
}
