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
    
    private let file: JSONFile<LockConfiguration>
    
    public var configuration: LockConfiguration {
        get async {
            await file.value
        }
    }
    
    // MARK: - Initialization
    
    public init(url: URL) async throws {
        self.file = try await JSONFile(url: url, defaultValue: LockConfiguration())
    }
    
    // MARK: - Methods
    
    public func update(_ configuration: LockConfiguration) async throws {
        try await file.write(configuration)
    }
}

