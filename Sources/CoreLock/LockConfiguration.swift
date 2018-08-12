//
//  LockConfiguration.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//
//

import Foundation

#if swift(>=3.2)
#elseif swift(>=3.0)
    import Codable
#endif

/// Lock Configuration
public struct LockConfiguration {
    
    /// Lock identifier UUID
    public let identifier: UUID
    
    /// Lock name
    public var name: String
    
    public init(identifier: UUID = UUID(),
                name: String = "") {
        
        self.identifier = identifier
        self.name = name
    }
}

// MARK: - Codable

extension LockConfiguration: Codable {
    
    public enum CodingKeys: String, CodingKey {
        
        case identifier
        case name
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.identifier = try container.decode(UUID.self, forKey: .identifier)
        self.name = try container.decode(String.self, forKey: .name)
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(identifier, forKey: .identifier)
        try container.encode(name, forKey: .name)
    }
}
