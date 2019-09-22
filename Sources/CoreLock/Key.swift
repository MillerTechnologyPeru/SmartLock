//
//  Key.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

/// A smart lock key.
public struct Key: Codable, Equatable, Hashable {
    
    /// The unique identifier of the key.
    public let identifier: UUID
    
    /// The name of the key.
    public let name: String
    
    /// Date key was created.
    public let created: Date
    
    /// Key's permissions. 
    public let permission: Permission
    
    public init(identifier: UUID = UUID(),
                name: String = "",
                created: Date = Date(),
                permission: Permission) {
        
        self.identifier = identifier
        self.name = name
        self.created = created
        self.permission = permission
    }
}

// MARK: - Supporting Types

public enum KeyType: UInt8, CaseIterable {
    
    case key        = 0x00
    case newKey     = 0x01
}

internal extension KeyType {
    
    init?(stringValue: String) {
        guard let value = type(of: self).allCases.first(where: { $0.stringValue == stringValue })
            else { return nil }
        self = value
    }
    
    var stringValue: String {
        switch self {
        case .key: return "key"
        case .newKey: return "newKey"
        }
    }
}

// MARK: - CustomStringConvertible

extension KeyType: CustomStringConvertible {
    
    public var description: String {
        return stringValue
    }
}

// MARK: - Codable

extension KeyType: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let value = KeyType(stringValue: rawValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid string value \(rawValue)")
        }
        self = value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
