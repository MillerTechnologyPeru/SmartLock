//
//  LockEvent.Cloud.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/14/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CloudKit
import CloudKitCodable
import CoreLock

public extension LockEvent {
    
    struct Cloud: Codable, Equatable {
        
        public let id: ID
        
        public let type: LockEvent.EventType
        
        public let lock: CloudLock.ID
        
        public let date: Date
        
        public let key: UUID
        
        public let newKey: UUID?
        
        public let removedKey: UUID?
        
        public let removedKeyType: KeyType?
        
        public let unlockAction: UnlockAction?
    }
}

internal extension LockEvent.Cloud {
    
    init(event: LockEvent, for lock: UUID) {
        
        self.lock = .init(rawValue: lock)
        switch event {
        case let .setup(event):
            self.type = .setup
            self.id = .init(rawValue: event.identifier)
            self.date = event.date
            self.key = event.key
            self.newKey = nil
            self.removedKey = nil
            self.removedKeyType = nil
            self.unlockAction = nil
        case let .unlock(event):
            self.type = .unlock
            self.id = .init(rawValue: event.identifier)
            self.date = event.date
            self.key = event.key
            self.unlockAction = event.action
            self.newKey = nil
            self.removedKey = nil
            self.removedKeyType = nil
        case let .createNewKey(event):
            self.type = .createNewKey
            self.id = .init(rawValue: event.identifier)
            self.date = event.date
            self.key = event.key
            self.newKey = event.newKey
            self.removedKey = nil
            self.removedKeyType = nil
            self.unlockAction = nil
        case let .confirmNewKey(event):
            self.type = .confirmNewKey
            self.id = .init(rawValue: event.identifier)
            self.date = event.date
            self.key = event.key
            self.newKey = event.newKey
            self.removedKey = nil
            self.removedKeyType = nil
            self.unlockAction = nil
        case let .removeKey(event):
            self.type = .removeKey
            self.id = .init(rawValue: event.identifier)
            self.date = event.date
            self.key = event.key
            self.removedKey = event.removedKey
            self.removedKeyType = event.type
            self.newKey = nil
            self.unlockAction = nil
        }
    }
}

internal extension LockEvent {
    
    init?(_ cloud: LockEvent.Cloud) {
        switch cloud.type {
        case .setup:
            self = .setup(.init(identifier: cloud.id.rawValue, date: cloud.date, key: cloud.key))
        case .unlock:
            guard let action = cloud.unlockAction
                else { return nil }
            self = .unlock(.init(identifier: cloud.id.rawValue, date: cloud.date, key: cloud.key, action: action))
        case .createNewKey:
            guard let newKey = cloud.newKey
                else { return nil }
            self = .createNewKey(.init(identifier: cloud.id.rawValue, date: cloud.date, key: cloud.key, newKey: newKey))
        case .confirmNewKey:
            guard let newKey = cloud.newKey
                else { return nil }
            self = .confirmNewKey(.init(identifier: cloud.id.rawValue, date: cloud.date, newKey: newKey, key: cloud.key))
        case .removeKey:
            guard let removedKey = cloud.removedKey,
                let removedKeyType = cloud.removedKeyType
                else { return nil }
            self = .removeKey(.init(identifier: cloud.id.rawValue, date: cloud.date, key: cloud.key, removedKey: removedKey, type: removedKeyType))
        }
    }
}

public extension LockEvent.Cloud {
    struct ID: RawRepresentable, Codable, Equatable, Hashable {
        public let rawValue: UUID
        public init(rawValue: UUID) {
            self.rawValue = rawValue
        }
    }
}

extension LockEvent.Cloud: CloudKitCodable {
    public var cloudIdentifier: CloudKitIdentifier {
        return id
    }
    public var parentRecord: CloudKitIdentifier? {
        return lock
    }
}

extension LockEvent.Cloud.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "Event"
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
    
    func fetchEvents(for lock: CloudLock.ID,
                     event: @escaping (LockEvent.Cloud) throws -> (Bool)) throws {
        
        let database = container.privateCloudDatabase
        
        let lockReference = CKRecord.Reference(
            recordID: lock.cloudRecordID,
            action: .none
        )
        
        let query = CKQuery(
            recordType: LockEvent.Cloud.ID.cloudRecordType,
            predicate: NSPredicate(format: "%K == %@", "lock", lockReference)
        )
        query.sortDescriptors = [
            .init(key: "date", ascending: false) // \LockEvent.Cloud.date
        ]
        
        let decoder = CloudKitDecoder(context: database)
        try database.queryAll(query) { (record) in
            let value = try decoder.decode(LockEvent.Cloud.self, from: record)
            return try event(value)
        }
    }
}
