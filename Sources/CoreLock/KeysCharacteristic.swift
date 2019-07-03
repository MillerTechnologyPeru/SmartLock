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
public struct KeysCharacteristic: GATTProfileCharacteristic, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "6AFA0D36-4567-4486-BEE5-E14A622B805F")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.notify]
    
    internal static let encoder = TLVEncoder()
    
    internal static let decoder = TLVDecoder()
    
    public let chunk: Chunk
    
    internal init(chunk: Chunk) {
        
        self.chunk = chunk
    }
    
    public init?(data: Data) {
        
        guard let chunk = Chunk(data: data)
            else { return nil }
        
        self.chunk = chunk
    }
    
    public var data: Data {
        
        return chunk.data
    }
}

public extension KeysCharacteristic {
    
    static func from(chunks: [Chunk]) throws -> EncryptedData {
        
        let data = Data(chunks: chunks)
        guard let value = try? decoder.decode(EncryptedData.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
    
    static func from(chunks: [Chunk], secret: KeyData) throws -> KeysList {
        
        let encryptedData = try from(chunks: chunks)
        let data = try encryptedData.decrypt(with: secret)
        guard let value = try? decoder.decode(KeysArray.self, from: data)
            else { throw GATTError.invalidData(data) }
        return KeysList(value)
    }
    
    static func from(_ value: EncryptedData, maximumUpdateValueLength: Int) throws -> [KeysCharacteristic] {
        
        let data = try encoder.encode(value)
        let chunks = Chunk.from(data, maximumUpdateValueLength: maximumUpdateValueLength)
        return chunks.map { KeysCharacteristic(chunk: $0) }
    }
    
    static func from(_ value: KeysList,
                     sharedSecret: KeyData,
                     maximumUpdateValueLength: Int) throws -> [KeysCharacteristic] {
        
        let encodedValue = KeysArray(value)
        let data = try encoder.encode(encodedValue)
        let encryptedData = try EncryptedData(encrypt: data, with: sharedSecret)
        return try from(encryptedData, maximumUpdateValueLength: maximumUpdateValueLength)
    }
}

public struct KeysList: Codable, Equatable {
    
    public let keys: [Key]
    
    public let newKeys: [NewKey]
    
    public init(keys: [Key], newKeys: [NewKey]) {
        
        self.keys = keys
        self.newKeys = newKeys
    }
}

internal extension KeysList {
    
    init(_ keysArray: KeysCharacteristic.KeysArray) {
        
        var keys = [Key]()
        var newKeys = [NewKey]()
        
        keysArray.keys.forEach {
            switch $0 {
            case let .key(key):
                keys.append(key)
            case let .newKey(newKey):
                newKeys.append(newKey)
            }
        }
        
        self.keys = keys
        self.newKeys = newKeys
    }
}

internal extension KeysCharacteristic.KeysArray {
    
    init(_ list: KeysList) {
        
        var keys = [Element]()
        keys.reserveCapacity(list.keys.count + list.newKeys.count)
        
        list.keys.forEach { keys.append(.key($0)) }
        list.newKeys.forEach { keys.append(.newKey($0)) }
        
        self.keys = keys
    }
}

internal extension KeysCharacteristic {
    
    struct KeysArray {
        
        enum Element {
            case key(Key)
            case newKey(NewKey)
        }
        
        public var keys: [Element]
    }
}

extension KeysCharacteristic.KeysArray.Element: Codable {
    
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

extension KeysCharacteristic.KeysArray: Codable {
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        let elements = try container.decode([Element].self)
        self.keys = elements
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        try container.encode(keys)
    }
}
