//
//  NewKeyInvitation.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/20/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CloudKit
import CloudKitCodable
import CoreLock

public extension NewKey.Invitation {
    
    struct Cloud: Codable, Equatable {
        
        public let id: ID
        
        /// Identifier of lock.
        public let lock: UUID
        
        /// New Key to create.
        public let key: Data // JSON Data
        
        /// Temporary shared secret to accept the key invitation.
        public let secret: KeyData
    }
}

internal extension NewKey.Invitation.Cloud {
    
    static let keyEncoder = JSONEncoder()
    
    static let keyDecoder = JSONDecoder()
}

internal extension NewKey.Invitation.Cloud {
    
    init(_ value: NewKey.Invitation) {
        
        self.id = .init(rawValue: value.key.identifier)
        self.lock = value.lock
        self.secret = value.secret
        self.key = try! NewKey.Invitation.Cloud.keyEncoder.encode(value.key)
    }
}

internal extension NewKey.Invitation {
    
    init?(_ cloud: NewKey.Invitation.Cloud) {
        
        guard let key = try? NewKey.Invitation.Cloud.keyDecoder.decode(NewKey.self, from: cloud.key)
            else { return nil }
        
        self.init(lock: cloud.lock, key: key, secret: cloud.secret)
    }
}

public extension NewKey.Invitation.Cloud {
    struct ID: RawRepresentable, Codable, Equatable, Hashable {
        public let rawValue: UUID
        public init(rawValue: UUID) {
            self.rawValue = rawValue
        }
    }
}

extension NewKey.Invitation.Cloud: CloudKitCodable {
    public var cloudIdentifier: CloudKitIdentifier {
        return id
    }
    public var parentRecord: CloudKitIdentifier? {
        return nil
    }
}

extension NewKey.Invitation.Cloud.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "NewKeyInvitation"
    }
    
    public init?(cloudRecordID: CKRecord.ID) {
        let string = cloudRecordID.recordName
            .replacingOccurrences(of: type(of: self).cloudRecordType + "/", with: "")
        guard let rawValue = UUID(uuidString: string)
            else { return nil }
        self.init(rawValue: rawValue)
    }
    
    public var cloudRecordID: CKRecord.ID {
        return CKRecord.ID(recordName: type(of: self).cloudRecordType + "/" + rawValue.uuidString, zoneID: .lockShared)
    }
}

// MARK: - CloudKit Fetch

internal extension CloudStore {
    
    func fetchSharedNewKeyInvitations() throws -> [NewKey.Invitation.Cloud] {
        
        typealias CloudValue = NewKey.Invitation.Cloud
        
        let database = container.sharedCloudDatabase
        
        let query = CKQuery(
            recordType: CloudValue.ID.cloudRecordType,
            predicate: NSPredicate(value: true)
        )
        
        let decoder = CloudKitDecoder(context: database)
        let records = try database.queryAll(query)
        return try records.map { try decoder.decode(CloudValue.self, from: $0) }
    }
}
