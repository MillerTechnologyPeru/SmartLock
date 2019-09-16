//
//  CloudUser.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/13/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CloudKit
import CloudKitCodable

/// CloudKit Lock User
public struct CloudUser: Codable, Equatable {
    
    public let id: ID
    
    public var applicationData: ApplicationData.Cloud?
}

public extension CloudUser {
    
    static func fetch(in container: CKContainer = .lock,
                      database scope: CKDatabase.Scope = .private) throws -> CloudUser {
        
        let recordID = try container.fetchUserRecordID()
        let database = container.database(with: scope)
        guard let record = try database.fetch(record: recordID) else {
            throw CKError(.unknownItem) // a user should always exist
        }
        let decoder = CloudKitDecoder(context: database)
        return try decoder.decode(self, from: record)
    }
}

public extension CloudUser {
    struct ID: RawRepresentable, Codable, Equatable, Hashable {
        public let rawValue: String
        public init(rawValue: String = UUID().uuidString) {
            self.rawValue = rawValue
        }
    }
}

extension CloudUser: CloudKitCodable {
    public var cloudIdentifier: CloudKitIdentifier {
        return id
    }
}

extension CloudUser.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return CKRecord.SystemType.userRecord
    }
    
    public init?(cloudRecordID: CKRecord.ID) {
        self.init(rawValue: cloudRecordID.recordName)
    }
    
    public var cloudRecordID: CKRecord.ID {
        return CKRecord.ID(recordName: rawValue)
    }
}
