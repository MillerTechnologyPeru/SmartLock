//
//  LockCloud.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/14/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import CloudKitCodable
import CoreLock

/// CloudKit Lock
public struct CloudLock {
    
    public let id: ID
    
    public var name: String
    
    public var information: LockCache.Information.Cloud
    
    public var keys: [Key.Cloud]
    
    public var newKeys: [NewKey.Cloud]
}

public extension CloudLock {
    
    init?(managedObject: LockManagedObject) {
        
        guard let identifier = managedObject.identifier,
            let name = managedObject.name,
            let information = managedObject.information
                .flatMap({ LockCache.Information(managedObject: $0) })
                .flatMap({ LockCache.Information.Cloud(id: identifier, value: $0) })
            else { return nil }
        
        self.id = .init(rawValue: identifier)
        self.name = name
        self.information = information
        self.keys = ((managedObject.keys as? Set<KeyManagedObject>) ?? [])
            .lazy
            .compactMap { Key(managedObject: $0) }
            .lazy
            .compactMap { Key.Cloud($0, lock: identifier) }
            .sorted(by: { $0.created < $1.created })
        self.newKeys = ((managedObject.pendingKeys as? Set<NewKeyManagedObject>) ?? [])
            .lazy
            .compactMap { NewKey(managedObject: $0) }
            .lazy
            .compactMap { NewKey.Cloud($0, lock: identifier) }
            .sorted(by: { $0.created < $1.created })
    }
}

public extension CloudLock {
    struct ID: RawRepresentable, Codable, Equatable, Hashable {
        public let rawValue: UUID
        public init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }
    }
}

extension CloudLock: CloudKitCodable {
    public var cloudIdentifier: CloudKitIdentifier {
        return id
    }
}

extension CloudLock.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "Lock"
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
