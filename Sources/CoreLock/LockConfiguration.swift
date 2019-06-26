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
    
    public init(identifier: UUID = UUID()) {
        
        self.identifier = identifier
    }
}
