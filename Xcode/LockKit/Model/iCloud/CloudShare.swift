//
//  CloudShare.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CloudKit
import CloudKitCodable
import CoreLock
import Predicate

#if os(iOS)
import UIKit
#endif

public enum CloudShare {
    
    public enum ShareType: String {
        
        case newKey = "com.colemancda.Lock.CloudKit.Share.NewKey"
    }
    
    public struct NewKey: Codable, Equatable, Identifiable {
        
        /// Identifier
        public let id: ID
        
        /// New Key invitation share URL
        public let invitation: URL
        
        /// User recieving the new key.
        public let user: String
    }
}

public extension CloudShare.NewKey {
    struct ID: RawRepresentable, Codable, Equatable, Hashable {
        public let rawValue: UUID
        public init(rawValue: UUID) {
            self.rawValue = rawValue
        }
    }
}

extension CloudShare.NewKey: CloudKitCodable {
    public var cloudIdentifier: CloudKitIdentifier {
        return id
    }
    public var parentRecord: CloudKitIdentifier? {
        return nil
    }
}

extension CloudShare.NewKey.ID: CloudKitIdentifier {
    
    public static var cloudRecordType: CKRecord.RecordType {
        return "NewKeyShare"
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

internal extension CloudStore {
    
    func fetchNewKeyPublicShares(
        for user: CKRecord.ID? = nil
    ) async throws -> AsyncThrowingMapSequence<AsyncThrowingStream<CKRecord, Swift.Error>, CloudShare.NewKey> {
        let database = container.publicCloudDatabase
        let decoder = CloudKitDecoder(context: database)
        let userID: CKRecord.ID
        if let id = user {
            userID = id
        } else {
            userID = try await container.fetchUserRecordID()
        }
        let predicate = (.keyPath("user") == .value(.string(userID.recordName))).toFoundation()
        assert(predicate == NSPredicate(format: "%K == %@", "user", userID.recordName))
        let query = CKQuery(
            recordType: CloudShare.NewKey.ID.cloudRecordType,
            predicate: predicate
        )
        return database.queryAll(query)
            .map { try decoder.decode(CloudShare.NewKey.self, from: $0) }
    }
}

// MARK: - CloudKit Subscriptions

public extension CloudStore {
    
    func subcribeNewKeyShares() async throws {
        let user = try await container.fetchUserRecordID()
        let predicate = (.keyPath("user") == .value(.string(user.recordName))).toFoundation()
        assert(predicate == NSPredicate(format: "%K == %@", "user", user.recordName))
        let subcription = CKQuerySubscription(
            recordType: CloudShare.NewKey.ID.cloudRecordType,
            predicate: predicate,
            options: [.firesOnRecordCreation]
        )
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subcription.notificationInfo = notificationInfo
        try await container.publicCloudDatabase.modify(subscriptions: [subcription])
    }
}

// MARK: - CloudKit Zone

public extension CKRecordZone.ID {
    
    static var lockShared: CKRecordZone.ID {
        return .init(zoneName: "shared", ownerName: CKCurrentUserDefaultName)
    }
}

// MARK: - CloudKit Sharing

public extension CloudStore {
    
    func share(
        _ invitation: NewKey.Invitation,
        to user: CloudUser.ID
    ) async throws {
        
        // make sure zone is created
        let zone = CKRecordZone(zoneID: .lockShared)
        try await container.privateCloudDatabase.modifyZones(save: [zone])
        
        // save invitation
        let cloudInvitation = NewKey.Invitation.Cloud(invitation)
        let privateCloudEncoder = CloudKitEncoder(context: container.privateCloudDatabase)
        let operation = try privateCloudEncoder.encode(cloudInvitation)
        guard let invitationRecord = operation.recordsToSave?.first
            else { fatalError() }
        assert(cloudInvitation.cloudIdentifier.cloudRecordID == invitationRecord.recordID)
        assert(type(of: cloudInvitation.cloudIdentifier).cloudRecordType == invitationRecord.recordType)
        operation.isAtomic = true
        operation.savePolicy = .allKeys
        
        // create private data share
        let invitationShare = CKShare(
            rootRecord: invitationRecord,
            shareID: CKRecord.ID(recordName: UUID().uuidString, zoneID: .lockShared)
        )
        invitationShare.publicPermission = .none
        invitationShare[CKShare.SystemFieldKey.title] = "New \(invitation.key.permission.type.localizedText) key"
        #if os(iOS)
        //invitationShare[CKShare.SystemFieldKey.thumbnailImageData] = UIImage(permission: invitation.key.permission).pngData()
        #endif
        invitationShare[CKShare.SystemFieldKey.shareType] = CloudShare.ShareType.newKey.rawValue
        
        // add shared user
        let participant = try await container.fetchShareParticipant(.init(userRecordID: user.cloudRecordID))
        participant.permission = .readWrite
        invitationShare.addParticipant(participant)
        
        // upload share
        operation.recordsToSave?.append(invitationShare)
        try await container.privateCloudDatabase.modify(operation)
        guard let shareURL = invitationShare.url else {
            assertionFailure("Missing CloudKit share URL")
            throw CKError(.internalError)
        }
        
        // upload public share data with invitation url
        let publicShare = CloudShare.NewKey(
            id: .init(rawValue: invitation.key.id),
            invitation: shareURL,
            user: user.cloudRecordID.recordName
        )
        
        try await upload(publicShare, database: .public)
    }
    
    func fetchNewKeyShares(
        invitations: ([NewKey.Invitation]) async throws -> ()
    ) async throws {
        
        // fetch public shares
        let publicShares = try await fetchNewKeyPublicShares()
            .reduce(into: [CloudShare.NewKey](), { $0.append($1) })
        guard publicShares.isEmpty == false else { return }
        
        // accept pending shares
        let shareURLs = publicShares.map { $0.invitation }
        let metadata = try await container.fetchShareMetadata(for: shareURLs, shouldFetchRootRecord: true)
            .reduce(into: [CKShare.Metadata](), { $0.append($1.1) })
        assert(metadata.count == publicShares.count)
        let pendingShares = metadata.filter { $0.participantStatus == .pending }
        if pendingShares.isEmpty == false {
            let _ = try await container.acceptShares(pendingShares)
                .reduce(into: [], { $0.append($1) })
        }
        
        let sharedRecords = metadata.compactMap { $0.rootRecord }
        assert(sharedRecords.count == metadata.count)
        
        let sharedDecoder = CloudKitDecoder(context: container.sharedCloudDatabase)
        let sharedInvitations = try sharedRecords
            .map { try sharedDecoder.decode(NewKey.Invitation.Cloud.self, from: $0) }
            .compactMap { NewKey.Invitation($0) }
        assert(sharedInvitations.count == sharedRecords.count)
        
        // handle invitations
        try await invitations(sharedInvitations) // won't delete if error is thrown
        
        // delete shares
        let deleteSharesOperation = CKModifyRecordsOperation(
            recordsToSave: [],
            recordIDsToDelete: metadata.map { $0.share.recordID }
        )
        deleteSharesOperation.isAtomic = true
        try await container.sharedCloudDatabase.modify(deleteSharesOperation)
        
        // delete public share data
        let deletePublicSharesOperation = CKModifyRecordsOperation(
            recordsToSave: [],
            recordIDsToDelete: publicShares.map { $0.id.cloudRecordID }
        )
        deletePublicSharesOperation.isAtomic = true
        try await container.publicCloudDatabase.modify(deletePublicSharesOperation)
    }
}
