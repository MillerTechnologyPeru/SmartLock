//
//  LockConfigurationStore.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation

/// Lock Configuration Storage
public protocol LockConfigurationStore: AnyObject {
    
    var configuration: LockConfiguration { get async }
    
    func update(_ configuration: LockConfiguration) async throws
}

// MARK: - Supporting Types

public actor InMemoryLockConfigurationStore: LockConfigurationStore {
    
    public private(set) var configuration: LockConfiguration
    
    public init(configuration: LockConfiguration = LockConfiguration()) {
        self.configuration = configuration
    }
    
    public func update(_ configuration: LockConfiguration) throws {
        self.configuration = configuration
    }
}
