//
//  CloudPermission.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/19/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CloudKit
import CloudKitCodable
import CoreLock

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

internal extension Permission.Schedule.Cloud {
    
    init(_ value: Permission.Schedule, key: UUID, type: KeyType) {
        self.id = .init(key: key, type: type)
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

internal extension Permission.Schedule {
    
    init?(_ cloud: Cloud) {
        
        guard let interval = Interval(rawValue: cloud.intervalMin ... cloud.intervalMax)
            else { return nil }
        
        let weekdays = Weekdays(
            sunday: cloud.sunday,
            monday: cloud.monday,
            tuesday: cloud.tuesday,
            wednesday: cloud.wednesday,
            thursday: cloud.thursday,
            friday: cloud.friday,
            saturday: cloud.saturday
        )
        
        self.init(
            expiry: cloud.expiry,
            interval: interval,
            weekdays: weekdays
        )
    }
}

public extension Permission.Schedule.Cloud {
    
    /// Identifier
    enum ID: Equatable, Hashable {
        case key(Key.Cloud.ID)
        case newKey(NewKey.Cloud.ID)
    }
}

public extension Permission.Schedule.Cloud.ID {
    
    init(key: UUID, type: KeyType) {
        switch type {
        case .key:
            self = .key(.init(rawValue: key))
        case .newKey:
            self = .newKey(.init(rawValue: key))
        }
    }
    
    var type: KeyType {
        switch self {
        case .key: return .key
        case .newKey: return .newKey
        }
    }
}

extension Permission.Schedule.Cloud.ID: RawRepresentable {
    
    public init?(rawValue: String) {
        let components = rawValue.split(separator: "/")
        guard components.count == 3,
            let keyIdentifier = UUID(uuidString: String(components[1])),
            String(components[2]) == Swift.type(of: self).cloudRecordType
            else { return nil }
        let type: KeyType
        switch String(components[0]) {
        case Key.Cloud.ID.cloudRecordType:
            type = .key
        case NewKey.Cloud.ID.cloudRecordType:
            type = .newKey
        default:
            return nil
        }
        self.init(key: keyIdentifier, type: type)
    }
    
    public var rawValue: String {
        switch self {
        case let .key(key):
            return Key.Cloud.ID.cloudRecordType
            + "/" + key.rawValue.uuidString
            + "/" + Swift.type(of: self).cloudRecordType
        case let .newKey(newKey):
            return NewKey.Cloud.ID.cloudRecordType
            + "/" + newKey.rawValue.uuidString
            + "/" + Swift.type(of: self).cloudRecordType
        }
    }
}

extension Permission.Schedule.Cloud.ID: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let value = Permission.Schedule.Cloud.ID(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid string value \(rawValue)")
        }
        self = value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension Permission.Schedule.Cloud: CloudKitCodable {
    public var cloudIdentifier: CloudKitIdentifier {
        return id
    }
    public var parentRecord: CloudKitIdentifier? {
        switch id {
        case let .key(key):
            return key
        case let .newKey(newKey):
            return newKey
        }
    }
}

extension Permission.Schedule.Cloud.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "PermissionSchedule"
    }
    
    public init?(cloudRecordID: CKRecord.ID) {
        self.init(rawValue: cloudRecordID.recordName)
    }
    
    public var cloudRecordID: CKRecord.ID {
        return CKRecord.ID(recordName: rawValue)
    }
}
