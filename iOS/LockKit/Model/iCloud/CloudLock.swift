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
}

public extension CloudLock {
    
    init?(managedObject: LockManagedObject) {
        
        guard let identifier = managedObject.identifier,
            let name = managedObject.name
            else { return nil }
        
        self.id = .init(rawValue: identifier)
        self.name = name
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

// MARK: - CloudKit Fetch

public extension CloudStore {
    
    func fetchLocks(_ lock: @escaping (CloudLock) throws -> (Bool)) throws {
        
        let database = container.privateCloudDatabase
        
        let query = CKQuery(
            recordType: CloudLock.ID.cloudRecordType,
            predicate: NSPredicate(value: true)
        )
        
        let decoder = CloudKitDecoder(context: database)
        try database.queryAll(query) { (record) in
            let value = try decoder.decode(CloudLock.self, from: record)
            return try lock(value)
        }
    }
}
