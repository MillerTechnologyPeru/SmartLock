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
        
        public var name: String
        
        public let created: Date
        
        public let expiration: Date
        
        public let permissionType: PermissionType.Cloud
        
        public let schedule: Permission.Schedule.Cloud?
    }
}

public extension NewKey.Cloud {
    
    init(_ value: NewKey) {
        self.id = .init(rawValue: value.identifier)
        self.name = value.name
        self.created = value.created
        self.expiration = value.expiration
        self.permissionType = .init(value.permission.type)
        if case let .scheduled(schedule) = value.permission {
            self.schedule = Permission.Schedule.Cloud(id: value.identifier, value: schedule)
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
            identifier: id,
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