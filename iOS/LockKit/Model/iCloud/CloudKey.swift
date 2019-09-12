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
        
        /// The name of the key.
        public var name: String
        
        /// Date key was created.
        public let created: Date
        
        /// Key's permissions.
        public let permissionType: PermissionType
        
        /// Key Permission Schedule
        public let schedule: Permission.Schedule?
    }
}

public extension Key.Cloud {
    
    init(_ value: Key) {
        self.id = .init(rawValue: value.identifier)
        self.name = value.name
        self.created = value.created
        self.permissionType = value.permission.type
        if case let .scheduled(schedule) = value.permission {
            self.schedule = schedule
        } else {
            self.schedule = nil
        }
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
}

extension Key.Cloud.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "Key"
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

public extension Permission.Schedule {
    
    struct Cloud: Codable, Equatable {
        
        /// The unique identifier.
        public let id: ID
        
        /// The date this permission becomes invalid.
        public var expiry: Date?
        
        // The minute interval range the lock can be unlocked.
        public var intervalMin: UInt16
        public var intervalMax: UInt16
        
        // weekdays
        
        public var sunday: Bool
        public var monday: Bool
        public var tuesday: Bool
        public var wednesday: Bool
        public var thursday: Bool
        public var friday: Bool
        public var saturday: Bool
    }
}

public extension Permission.Schedule.Cloud {
    
    init(id: UUID, value: Permission.Schedule) {
        self.id = .init(rawValue: id)
        self.expiry = value.expiry
        self.intervalMin = value.interval.rawValue.lowerBound
        self.intervalMax = value.interval.rawValue.upperBound
        self.sunday = value.weekdays.sunday
        self.monday = value.weekdays.monday
        self.tuesday = value.weekdays.tuesday
        self.wednesday = value.weekdays.wednesday
        self.thursday = value.weekdays.thursday
        self.friday = value.weekdays.friday
        self.saturday = value.weekdays.saturday
    }
}

public extension Permission.Schedule.Cloud {
    struct ID: RawRepresentable, Codable, Equatable, Hashable {
        public let rawValue: UUID
        public init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }
    }
}

extension Permission.Schedule.Cloud: CloudKitCodable {
    public var cloudIdentifier: CloudKitIdentifier {
        return id
    }
}

extension Permission.Schedule.Cloud.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "PermissionSchedule"
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
