//
//  CloudApplicationData.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/11/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock
import CloudKit
import CloudKitCodable

public extension ApplicationData {
    
    struct Cloud: Codable, Equatable {
        public let id: Cloud.ID
        public let created: Date
        public var updated: Date
        public var locks: [LockCache.Cloud]
    }
}

public extension ApplicationData.Cloud {
    
    init(_ value: ApplicationData, user: CloudUser.ID) {
        
        self.id = .init(rawValue: value.identifier)
        self.created = value.created
        self.updated = value.updated
        self.locks = value.locks
            .sorted(by: { $0.key.uuidString > $1.key.uuidString })
            .map { LockCache.Cloud(lock: $0.key, cache: $0.value, applicationData: value.identifier) }
    }
}

public extension ApplicationData {
    
    init?(_ cloud: Cloud) {
        var locks = [UUID: LockCache]()
        for lock in cloud.locks {
            guard let value = LockCache(lock)
                else { return nil }
            locks[lock.id.rawValue] = value
        }
        self.init(
            identifier: cloud.id.rawValue,
            created: cloud.created,
            updated: cloud.updated,
            locks: locks
        )
    }
}

public extension ApplicationData.Cloud {
    struct ID: RawRepresentable, Codable, Equatable, Hashable {
        public let rawValue: UUID
        public init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }
    }
}

extension ApplicationData.Cloud: CloudKitCodable {
    public var cloudIdentifier: CloudKitIdentifier {
        return id
    }
}

extension ApplicationData.Cloud.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "ApplicationData"
    }
    
    public init?(cloudRecordID: CKRecord.ID) {
        let string = cloudRecordID.recordName
            .replacingOccurrences(of: type(of: self).cloudRecordType + "/", with: "")
        guard let rawValue = UUID(uuidString: string)
            else { return nil }
        self.init(rawValue: rawValue)
    }
    
    public var cloudRecordID: CKRecord.ID {
        return CKRecord.ID(recordName: type(of: self).cloudRecordType + "/" + rawValue.uuidString)
    }
}

public extension LockCache {
    
    struct Cloud: Codable, Equatable {
        
        /// Identifier
        public let id: ID
        
        public let applicationData: ApplicationData.Cloud.ID
        
        /// Stored key for lock.
        ///
        /// Can only have one key per lock.
        public let key: Key.Cloud
        
        /// User-friendly lock name
        public var name: String
        
        /// Lock information.
        public var information: LockCache.Information.Cloud
    }
}

internal extension LockCache.Cloud {
    
    init(lock: UUID,
         cache: LockCache,
         applicationData: UUID) {
        
        self.id = .init(rawValue: lock)
        self.key = .init(cache.key, lock: lock)
        self.applicationData = .init(rawValue: applicationData)
        self.name = cache.name
        self.information = .init(id: lock, value: cache.information)
    }
}

internal extension LockCache {
    
    init?(_ cloud: Cloud) {
        guard let key = Key(cloud.key),
            let information = Information(cloud.information)
            else { return nil }
        self.name = cloud.name
        self.key = key
        self.information = information
    }
}

public extension LockCache.Cloud {
    struct ID: RawRepresentable, Codable, Equatable, Hashable {
        public let rawValue: UUID
        public init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }
    }
}

extension LockCache.Cloud: CloudKitCodable {
    public var cloudIdentifier: CloudKitIdentifier {
        return id
    }
    public var parentRecord: CloudKitIdentifier? {
        return applicationData
    }
}

extension LockCache.Cloud.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "LockCache"
    }
    
    public init?(cloudRecordID: CKRecord.ID) {
        let string = cloudRecordID.recordName
            .replacingOccurrences(of: type(of: self).cloudRecordType + "/", with: "")
        guard let rawValue = UUID(uuidString: string)
            else { return nil }
        self.init(rawValue: rawValue)
    }
    
    public var cloudRecordID: CKRecord.ID {
        return CKRecord.ID(recordName: type(of: self).cloudRecordType + "/" + rawValue.uuidString)
    }
}

public extension LockCache.Information {
    
    struct Cloud: Codable, Equatable {
        
        /// Identifier
        public let id: ID
        
        /// Firmware build number
        public var buildVersion: String
        
        /// Firmware version
        public var version: String
        
        /// Device state
        public var status: LockStatus
        
        /// Supported lock actions
        public var unlockActions: Set<UnlockAction>
    }
}

internal extension LockCache.Information.Cloud {
    
    init(id: UUID, value: LockCache.Information) {
        self.id = .init(rawValue: id)
        self.buildVersion = value.buildVersion.description
        self.version = value.version.description
        self.status = value.status
        self.unlockActions = value.unlockActions
    }
}

internal extension LockCache.Information {
    
    init?(_ cloud: LockCache.Information.Cloud) {
        
        guard let buildVersion = UInt64(cloud.buildVersion).flatMap(LockBuildVersion.init),
            let version = LockVersion(rawValue: cloud.version)
            else { return nil }
        
        self.buildVersion = buildVersion
        self.version = version
        self.status = cloud.status
        self.unlockActions = cloud.unlockActions
    }
}

public extension LockCache.Information.Cloud {
    struct ID: RawRepresentable, Codable, Equatable, Hashable {
        public let rawValue: UUID
        public init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }
    }
}

extension LockCache.Information.Cloud: CloudKitCodable {
    public var cloudIdentifier: CloudKitIdentifier {
        return id
    }
    public var parentRecord: CloudKitIdentifier? {
        return LockCache.Cloud.ID(rawValue: id.rawValue)
    }
}

extension LockCache.Information.Cloud.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "LockInformation"
    }
    
    public init?(cloudRecordID: CKRecord.ID) {
        let string = cloudRecordID.recordName
            .replacingOccurrences(of: type(of: self).cloudRecordType + "/", with: "")
        guard let rawValue = UUID(uuidString: string)
            else { return nil }
        self.init(rawValue: rawValue)
    }
    
    public var cloudRecordID: CKRecord.ID {
        return CKRecord.ID(recordName: type(of: self).cloudRecordType + "/" + rawValue.uuidString)
    }
}
