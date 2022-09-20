//
//  CloudNewKey.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/14/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock
import CloudKit
import CloudKitCodable

public extension NewKey {
    
    struct Cloud: Codable, Equatable {
        
        public let id: ID
        
        /// Lock this key belongs to.
        public let lock: CloudLock.ID
        
        public var name: String
        
        public let created: Date
        
        public let expiration: Date
        
        public let permissionType: PermissionType
        
        public let schedule: Permission.Schedule.Cloud?
    }
}

public extension NewKey.Cloud {
    
    init(_ value: NewKey, lock: UUID) {
        self.id = .init(rawValue: value.id)
        self.lock = .init(rawValue: lock)
        self.name = value.name
        self.created = value.created
        self.expiration = value.expiration
        self.permissionType = value.permission.type
        if case let .scheduled(schedule) = value.permission {
            self.schedule = Permission.Schedule.Cloud(schedule, key: value.id, type: .newKey)
        } else {
            self.schedule = nil
        }
    }
}

public extension NewKey {
    
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
            id: id,
            name: cloud.name,
            permission: permission,
            created: cloud.created,
            expiration: cloud.expiration
        )
    }
}

public extension NewKey.Cloud {
    struct ID: RawRepresentable, Codable, Equatable, Hashable {
        public let rawValue: UUID
        public init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }
    }
}

extension NewKey.Cloud: CloudKitCodable {
    public var cloudIdentifier: CloudKitIdentifier {
        return id
    }
    public var parentRecord: CloudKitIdentifier? {
        return lock
    }
}

extension NewKey.Cloud.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "NewKey"
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

// MARK: - CloudKit Fetch

public extension CloudStore {
    
    func fetchNewKeys(
        for lock: CloudLock.ID
    ) -> AsyncThrowingMapSequence<AsyncThrowingStream<CKRecord, Swift.Error>, NewKey.Cloud> {
        let database = container.privateCloudDatabase
        let decoder = CloudKitDecoder(context: database)
        let lockReference = CKRecord.Reference(
            recordID: lock.cloudRecordID,
            action: .none
        )
        let query = CKQuery(
            recordType: NewKey.Cloud.ID.cloudRecordType,
            predicate: NSPredicate(format: "%K == %@", "lock", lockReference)
        )
        query.sortDescriptors = [
            .init(key: "created", ascending: false) // \Key.Cloud.created
        ]
        return database.queryAll(query)
            .map { try decoder.decode(NewKey.Cloud.self, from: $0) }
    }
}
