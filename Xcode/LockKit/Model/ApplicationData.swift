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
    public let id: UUID
    
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
        self.id = UUID()
        self.created = Date()
        self.updated = Date()
        self.locks = [:]
    }
    
    public init(id: UUID,
                created: Date,
                updated: Date,
                locks: [UUID: LockCache]) {
        
        self.id = id
        self.created = created
        self.updated = updated
        self.locks = locks
    }
}

public extension ApplicationData {
    
    var keys: [Key] {
        return locks
            .values
            .map { $0.key }
    }
    
    subscript (lock id: UUID) -> LockCache? {
        get { return locks[id] }
        set { locks[id] = newValue }
    }
    
    subscript (key id: UUID) -> Key? {
        return locks.values
            .lazy
            .map { $0.key }
            .first { $0.id == id }
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
    
    #if DEBUG
    public init(key: Key, name: String, information: Information) {
        self.key = key
        self.name = name
        self.information = information
    }
    #endif
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
        
        #if DEBUG
        public init(buildVersion: LockBuildVersion, version: LockVersion, status: LockStatus, unlockActions: Set<UnlockAction>) {
            self.buildVersion = buildVersion
            self.version = version
            self.status = status
            self.unlockActions = unlockActions
        }
        #endif
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

internal extension LockCache.Information {
    
    init(_ lock: LockInformation) {
        
        self.buildVersion = lock.buildVersion
        self.version = lock.version
        self.status = lock.status
        self.unlockActions = lock.unlockActions
    }
}
