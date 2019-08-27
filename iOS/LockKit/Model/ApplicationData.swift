//
//  ApplicationData.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/26/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock

/// Application Data.
public struct ApplicationData: Codable, Equatable {
    
    /// Identifier of app instance.
    public let identifier: UUID
    
    /// Date application data was created.
    public let created: Date
    
    /// Date application data was last modified.
    public private(set) var updated: Date
    
    /// Persistent lock information.
    public var locks: [UUID: LockCache] {
        didSet { if locks != oldValue { didUpdate() } }
    }
    
    /// Update date when modified.
    private mutating func didUpdate() {
        updated = Date()
    }
    
    /// Initialize a new application data.
    public init() {
        self.identifier = UUID()
        self.created = Date()
        self.updated = Date()
        self.locks = [:]
    }
}

public extension ApplicationData {
    
    var keys: [Key] {
        return locks.values.map { $0.key }
    }
}

// MARK: - JSON

extension ApplicationData: JSONCodable { }

// MARK: - Supporting Types

/// Lock Cache
public struct LockCache: Codable, Equatable {
    
    /// Stored key for lock.
    ///
    /// Can only have one key per lock.
    public let key: Key
    
    /// User-friendly lock name
    public var name: String
    
    /// Lock information.
    public var information: Information
}

public extension LockCache {
    
    /// Cached Lock Information.
    struct Information: Codable, Equatable {
        
        /// Firmware build number
        public var buildVersion: LockBuildVersion
        
        /// Firmware version
        public var version: LockVersion
        
        /// Device state
        public var status: LockStatus
        
        /// Supported lock actions
        public var unlockActions: Set<UnlockAction>
    }
}

internal extension LockCache.Information {
    
    init(characteristic: LockInformationCharacteristic) {
        
        self.buildVersion = characteristic.buildVersion
        self.version = characteristic.version
        self.status = characteristic.status
        self.unlockActions = Set(characteristic.unlockActions)
    }
}
