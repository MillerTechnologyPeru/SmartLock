//
//  LockConfiguration.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//
//

import Foundation

/// Lock Configuration
public struct LockConfiguration: Codable, Equatable, Hashable {
    
    /// Lock identifier UUID
    public let id: UUID
    
    /// Lock name
    public var name: String?
    
    public init(id: UUID = UUID(),
                name: String? = nil) {
        
        self.id = id
        self.name = name
    }
}
