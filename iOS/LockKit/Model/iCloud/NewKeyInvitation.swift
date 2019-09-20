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
        public let lock: CloudLock.ID
        
        /// New Key to create.
        public let key: NewKey.Cloud
        
        /// Temporary shared secret to accept the key invitation.
        public let secret: KeyData
    }
}

internal extension NewKey.Invitation.Cloud {
    
    init(_ value: NewKey.Invitation) {
        
        self.id = .init(rawValue: value.key.identifier)
        self.lock = .init(rawValue: value.lock)
        self.key = .init(value.key, lock: value.lock)
        self.secret = value.secret
    }
}

internal extension NewKey.Invitation {
    
    init(_ cloud: NewKey.Invitation.Cloud) {
        
        fatalError()
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
        return lock
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
        return CKRecord.ID(recordName: type(of: self).cloudRecordType + "/" + rawValue.uuidString)
    }
}
