//
//  LockCloud.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/14/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CloudKit
import CloudKitCodable
import CoreLock

public struct CloudLock {
    
    public let id: ID
    
    public var name: String
    
    public var information: LockCache.Information.Cloud
    
    public var keys: [Key.Cloud]
    
    public var newKeys: [NewKey.Cloud]
    
    public var events: [LockEvent.Cloud]
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
