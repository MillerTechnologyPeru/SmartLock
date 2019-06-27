//
//  LockConfiguration.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/13/18.
//
//

import Foundation
import CoreLock
import CoreLockGATTServer

/// Stores the lock configuration in a JSON file.
public final class LockConfigurationFile: LockConfigurationStore {
    
    // MARK: - Properties
    
    internal let file: JSONFile<LockConfiguration>
    
    public var configuration: LockConfiguration {
        return file.value
    }
    
    // MARK: - Initialization
    
    public init(url: URL) throws {
        
        self.file = try JSONFile(url: url, defaultValue: LockConfiguration())
    }
    
    // MARK: - Methods
    
    public func update(_ configuration: LockConfiguration) throws {
        
        try file.write(configuration)
    }
}

