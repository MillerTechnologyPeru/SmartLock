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
    
    static func from(chunks: [Chunk], sharedSecret: KeyData) throws -> KeysList {
        
        let encryptedData = try from(chunks: chunks)
        let data = try encryptedData.decrypt(with: sharedSecret)
        guard let value = try? decoder.decode(KeysList.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
    
    static func from(_ value: EncryptedData, maximumUpdateValueLength: Int) throws -> [KeysCharacteristic] {
        
        let data = try encoder.encode(value)
        let chunks = Chunk.from(data, maximumUpdateValueLength: maximumUpdateValueLength)
        return chunks.map { KeysCharacteristic(chunk: $0) }
    }
    
    static func from(_ value: KeysList,
                     sharedSecret: KeyData,
                     maximumUpdateValueLength: Int) throws -> [KeysCharacteristic] {
        
        let data = try encoder.encode(value)
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
