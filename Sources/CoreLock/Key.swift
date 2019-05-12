//
//  Key.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

/// A smart lock key.
public struct Key {
    
    /// The unique identifier of the key.
    public let identifier: UUID
    
    /// The name of the key.
    public let name: String
    
    /// Date key was created.
    public let date: Date
    
    /// Key's permissions. 
    public let permission: Permission
    
    public init(identifier: UUID = UUID(),
                name: String = "",
                date: Date = Date(),
                permission: Permission) {
        
        self.identifier = identifier
        self.name = name
        self.date = date
        self.permission = permission
    }
}

// MARK: - Equatable

extension Key: Equatable {
    
    public static func == (lhs: Key, rhs: Key) -> Bool {
        
        return lhs.identifier == rhs.identifier
            && lhs.permission == rhs.permission
            && lhs.name == rhs.name
            && lhs.date == rhs.date
    }
}

// MARK: - Codable

extension Key: Codable {
    
    public enum CodingKeys: String, CodingKey {
        
        case identifier
        case name
        case date
        case permission
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.identifier = try container.decode(UUID.self, forKey: .identifier)
        self.name = try container.decode(String.self, forKey: .name)
        self.permission = try container.decode(Permission.self, forKey: .permission)
        self.date = try container.decode(Date.self, forKey: .date)
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(identifier, forKey: .identifier)
        try container.encode(name, forKey: .name)
        try container.encode(permission, forKey: .permission)
        try container.encode(date, forKey: .date)
    }
}
