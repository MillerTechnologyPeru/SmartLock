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
    public let identifier: UUID
    
    /// Lock name
    public var name: String
    
    public init(identifier: UUID = UUID(),
                name: String = "") {
        
        self.identifier = identifier
        self.name = name
    }
}
