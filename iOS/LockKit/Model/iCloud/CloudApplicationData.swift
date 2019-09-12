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
    
    init(_ value: ApplicationData) {
        
        self.id = .init(rawValue: value.identifier)
        self.created = value.created
        self.updated = value.updated
        self.locks = value.locks
            .sorted(by: { $0.key.uuidString > $1.key.uuidString })
            .map { LockCache.Cloud(id: $0.key, value: $0.value) }
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
        guard let rawValue = UUID(uuidString: cloudRecordID.recordName)
            else { return nil }
        self.init(rawValue: rawValue)
    }
    
    public var cloudRecordID: CKRecord.ID {
        return CKRecord.ID(recordName: rawValue.uuidString)
    }
}

public extension LockCache {
    
    struct Cloud: Codable, Equatable {
        
        /// Identifier
        public let id: ID
        
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

public extension LockCache.Cloud {
    
    init(id: UUID, value: LockCache) {
        self.id = .init(rawValue: id)
        self.key = .init(value.key)
        self.name = value.name
        self.information = .init(id: id, value: value.information)
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
}

extension LockCache.Cloud.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "LockCache"
    }
    
    public init?(cloudRecordID: CKRecord.ID) {
        guard let rawValue = UUID(uuidString: cloudRecordID.recordName)
            else { return nil }
        self.init(rawValue: rawValue)
    }
    
    public var cloudRecordID: CKRecord.ID {
        return CKRecord.ID(recordName: rawValue.uuidString)
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

public extension LockCache.Information.Cloud {
    
    init(id: UUID, value: LockCache.Information) {
        self.id = .init(rawValue: id)
        self.buildVersion = value.buildVersion.description
        self.version = value.version.description
        self.status = value.status
        self.unlockActions = value.unlockActions
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
}

extension LockCache.Information.Cloud.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "LockInformation"
    }
    
    public init?(cloudRecordID: CKRecord.ID) {
        guard let rawValue = UUID(uuidString: cloudRecordID.recordName)
            else { return nil }
        self.init(rawValue: rawValue)
    }
    
    public var cloudRecordID: CKRecord.ID {
        return CKRecord.ID(recordName: rawValue.uuidString)
    }
}
