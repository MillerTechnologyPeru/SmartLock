//
//  Key.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

#if swift(>=3.2)
#elseif swift(>=3.0)
    import Codable
#endif

/// A smart lock key.
public struct Key {
    
    public let identifier: UUID
    
    public let name: String
    
    public let permission: Permission
    
    public init(identifier: UUID = UUID(),
                name: String = "",
                permission: Permission) {
        
        self.identifier = identifier
        self.name = name
        self.permission = permission
    }
}

// MARK: - Codable

extension Key: Codable {
    
    public enum CodingKeys: String, CodingKey {
        
        case identifier
        case permission
        case name
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.identifier = try container.decode(UUID.self, forKey: .identifier)
        self.name = try container.decode(String.self, forKey: .name)
        self.permission = try container.decode(Permission.self, forKey: .permission)
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(identifier, forKey: .identifier)
        try container.encode(name, forKey: .name)
        try container.encode(permission, forKey: .permission)
    }
}
