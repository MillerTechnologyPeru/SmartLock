//
//  CloudKey.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/11/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock
import CloudKit
import CloudKitCodable

public extension Key {
    
    struct Cloud: Codable, Equatable {
        
        /// The unique identifier of the key.
        public let id: ID
        
        /// Lock this key belongs to.
        public let lock: CloudLock.ID
        
        /// The name of the key.
        public var name: String
        
        /// Date key was created.
        public let created: Date
        
        /// Key's permissions.
        public let permissionType: PermissionType.Cloud
        
        /// Key Permission Schedule
        public let schedule: Permission.Schedule.Cloud?
    }
}

public extension Key.Cloud {
    
    init(_ value: Key, lock: UUID) {
        self.id = .init(rawValue: value.identifier)
        self.lock = .init(rawValue: lock)
        self.name = value.name
        self.created = value.created
        self.permissionType = .init(value.permission.type)
        if case let .scheduled(schedule) = value.permission {
            self.schedule = Permission.Schedule.Cloud(schedule, key: value.identifier, type: .key)
        } else {
            self.schedule = nil
        }
    }
}

public extension Key {
    
    init?(_ cloud: Cloud) {
        
        let id = cloud.id.rawValue
        let permission: Permission
        
        switch cloud.permissionType {
        case .owner:
            permission = .owner
        case .admin:
            permission = .admin
        case .anytime:
            permission = .anytime
        case .scheduled:
            guard let cloudSchedule = cloud.schedule,
                let schedule = Permission.Schedule(cloudSchedule)
                else { return nil }
            permission = .scheduled(schedule)
        }
        
        self.init(
            identifier: id,
            name: cloud.name,
            created: cloud.created,
            permission: permission
        )
    }
}

public extension Key.Cloud {
    struct ID: RawRepresentable, Codable, Equatable, Hashable {
        public let rawValue: UUID
        public init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }
    }
}

extension Key.Cloud: CloudKitCodable {
    public var cloudIdentifier: CloudKitIdentifier {
        return id
    }
    public var parentRecord: CloudKitIdentifier? {
        return lock
    }
}

extension Key.Cloud.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "Key"
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

// MARK: - Supporting Types

public extension KeyType {
    
    enum Cloud: String, Codable {
        
        case key
        case newKey
    }
}

public extension KeyType.Cloud {
    
    init(_ value: KeyType) {
        self = unsafeBitCast(value, to: KeyType.Cloud.self)
    }
}

public extension KeyType {
    
    init(_ value: KeyType.Cloud) {
        self = unsafeBitCast(value, to: KeyType.self)
    }
}

// MARK: - CloudKit Fetch

public extension CloudStore {
    
    func fetchKeys(for lock: CloudLock.ID,
                   result: @escaping (Key.Cloud) throws -> (Bool)) throws {
        
        let database = container.privateCloudDatabase
        
        let lockReference = CKRecord.Reference(
            recordID: lock.cloudRecordID,
            action: .none
        )
        
        let query = CKQuery(
            recordType: Key.Cloud.ID.cloudRecordType,
            predicate: NSPredicate(format: "%K == %@", "lock", lockReference)
        )
        query.sortDescriptors = [
            .init(key: "created", ascending: false) // \Key.Cloud.created
        ]
        
        let decoder = CloudKitDecoder(context: database)
        try database.queryAll(query) { (record) in
            let value = try decoder.decode(Key.Cloud.self, from: record)
            return try result(value)
        }
    }
}
