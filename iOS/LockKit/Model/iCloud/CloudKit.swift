//
//  CloudKit.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/15/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CloudKit

public extension CKContainer {
    
    convenience init(identifier: UbiquityContainerIdentifier) {
        self.init(identifier: identifier.rawValue)
    }
}

public extension CKContainer {
    
    /// `iCloud.com.colemancda.Lock` CloudKit container.
    static var lock: CKContainer {
        struct Cache {
            static let container = CKContainer(identifier: .lock)
        }
        return Cache.container
    }
}

internal extension CKContainer {
    
    func accountStatus() throws -> CKAccountStatus {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<CKAccountStatus, Swift.Error>!
        accountStatus { (status, error) in
            defer { semaphore.signal() }
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(status)
            }
        }
        semaphore.wait()
        switch result! {
        case let .success(status):
            return status
        case let .failure(error):
            throw error
        }
    }
    
    func fetchUserRecordID() throws -> CKRecord.ID {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<CKRecord.ID, Swift.Error>!
        fetchUserRecordID { (recordID, error) in
            defer { semaphore.signal() }
            if let recordID = recordID {
                result = .success(recordID)
            } else if let error = error {
                result = .failure(error)
            } else {
                fatalError()
            }
        }
        semaphore.wait()
        switch result! {
        case let .success(recordID):
            return recordID
        case let .failure(error):
            throw error
        }
    }
    
    func requestApplicationPermission(_ permissions: CKContainer_Application_Permissions) throws -> CKContainer_Application_PermissionStatus {
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<CKContainer_Application_PermissionStatus, Swift.Error>!
        requestApplicationPermission(permissions) { (status, error) in
            defer { semaphore.signal() }
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(status)
            }
        }
        semaphore.wait()
        switch result! {
        case let .success(status):
            return status
        case let .failure(error):
            throw error
        }
    }
    
    func discoverAllUserIdentities(user: @escaping (CKUserIdentity) -> ()) throws {
        let operation = CKDiscoverAllUserIdentitiesOperation()
        var cloudKitError: Swift.Error?
        let semaphore = DispatchSemaphore(value: 0)
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        operation.userIdentityDiscoveredBlock = user
        operation.discoverAllUserIdentitiesCompletionBlock = {
            cloudKitError = $0
            semaphore.signal()
        }
        add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
    }
    
    func discoverUserIdentities(_ userIdentityLookupInfos: [CKUserIdentity.LookupInfo], found: @escaping ((CKUserIdentity, CKUserIdentity.LookupInfo) -> ())) throws {
        
        let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: userIdentityLookupInfos)
        var cloudKitError: Swift.Error?
        let semaphore = DispatchSemaphore(value: 0)
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        operation.userIdentityDiscoveredBlock = found
        operation.discoverUserIdentitiesCompletionBlock = {
            cloudKitError = $0
            semaphore.signal()
        }
        add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
    }
    
    func fetchShareParticipants(_ userIdentityLookupInfos: [CKUserIdentity.LookupInfo], shareParticipantFetched: @escaping ((CKShare.Participant) -> ())) throws {
        
        let operation = CKFetchShareParticipantsOperation(userIdentityLookupInfos: userIdentityLookupInfos)
        var cloudKitError: Swift.Error?
        let semaphore = DispatchSemaphore(value: 0)
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        operation.shareParticipantFetchedBlock = shareParticipantFetched
        operation.fetchShareParticipantsCompletionBlock = {
            cloudKitError = $0
            semaphore.signal()
        }
        add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
    }
    
    func fetchShareParticipant(_ userIdentity: CKUserIdentity.LookupInfo) throws -> CKShare.Participant {
        
        var participant: CKShare.Participant?
        try fetchShareParticipants([userIdentity]) {
            participant = $0
        }
        guard let foundUser = participant else {
            assertionFailure("Expected a participant")
            throw CKError(.internalError)
        }
        return foundUser
    }
    
    /// An operation that fetches shared record metadata for one or more shares.
    func fetchShareMetadata(for shareURLs: [URL], shouldFetchRootRecord: Bool = false) throws -> [URL: CKShare.Metadata] {
        
        let operation = CKFetchShareMetadataOperation(shareURLs: shareURLs)
        var cloudKitError: Swift.Error?
        let semaphore = DispatchSemaphore(value: 0)
        var shares = [URL: CKShare.Metadata](minimumCapacity: shareURLs.count)
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        operation.shouldFetchRootRecord = shouldFetchRootRecord
        operation.perShareMetadataBlock = { (url, metadata, error) in
            if let error = error {
                operation.cancel()
                cloudKitError = error
                semaphore.signal()
            } else if let metadata = metadata {
                shares[url] = metadata
            } else {
                assertionFailure("Missing share metadata")
            }
        }
        operation.fetchShareMetadataCompletionBlock = {
            cloudKitError = $0
            semaphore.signal()
        }
        add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
        return shares
    }
    
    func acceptShares(_ shares: [CKShare.Metadata]) throws {
        
        let operation = CKAcceptSharesOperation(shareMetadatas: shares)
        var cloudKitError: Swift.Error?
        let semaphore = DispatchSemaphore(value: 0)
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        operation.perShareCompletionBlock = { (metadata, share, error) in
            if let error = error {
                operation.cancel()
                cloudKitError = error
                semaphore.signal()
            }
        }
        operation.acceptSharesCompletionBlock = {
            cloudKitError = $0
            semaphore.signal()
        }
        add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
    }
}

internal extension CKDatabase {
    
    @discardableResult
    func fetch(_ operation: CKFetchRecordsOperation) throws -> [CKRecord.ID: CKRecord] {
        
        var cloudKitError: Swift.Error?
        var recordsByRecordID = [CKRecord.ID: CKRecord]()
        let semaphore = DispatchSemaphore(value: 0)
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        operation.fetchRecordsCompletionBlock = {
            recordsByRecordID = $0 ?? [:]
            cloudKitError = $1
            semaphore.signal()
        }
        add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
        return recordsByRecordID
    }
    
    func modify(_ operation: CKModifyRecordsOperation) throws {
        
        var cloudKitError: Swift.Error?
        let semaphore = DispatchSemaphore(value: 0)
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        operation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecords, error) in
            cloudKitError = error
            semaphore.signal()
        }
        add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
    }
    
    @discardableResult
    func query(_ operation: CKQueryOperation,
               record: @escaping (CKRecord) throws -> (Bool)) throws -> CKQueryOperation.Cursor? {
        
        var cursor: CKQueryOperation.Cursor?
        var cloudKitError: Swift.Error?
        let semaphore = DispatchSemaphore(value: 0)
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        operation.queryCompletionBlock = {
            cursor = $0
            cloudKitError = $1
            semaphore.signal()
        }
        operation.recordFetchedBlock = {
            do {
                if try record($0) == false {
                    operation.cancel()
                    semaphore.signal()
                }
            }
            catch { cloudKitError = error }
        }
        add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
        return cursor
    }
    
    func queryAll(_ query: CKQuery,
                  zone: CKRecordZone.ID? = nil,
                  record: @escaping (CKRecord) throws -> (Bool)) throws {
        
        var operation = CKQueryOperation(query: query)
        operation.zoneID = zone
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        var cursor = try self.query(operation, record: record)
        while let queryCursor = cursor {
            operation = .init(cursor: queryCursor)
            operation.zoneID = zone
            cursor = try self.query(operation, record: record)
        }
    }
    
    func queryAll(_ query: CKQuery, zone: CKRecordZone.ID? = nil) throws -> [CKRecord] {
        var records = [CKRecord]()
        try queryAll(query, zone: zone) {
            records.append($0)
            return true
        }
        return records
    }
    
    func modifyZones(save: [CKRecordZone]?,
                     delete: [CKRecordZone.ID]? = nil) throws {
        
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: save, recordZoneIDsToDelete: delete)
        var cloudKitError: Swift.Error?
        let semaphore = DispatchSemaphore(value: 0)
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        operation.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
            cloudKitError = error
            semaphore.signal()
        }
        add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
    }
    
    func fetchZones(_ zones: [CKRecordZone.ID]? = nil) throws -> [CKRecordZone.ID: CKRecordZone] {
        
        let operation = zones.flatMap { CKFetchRecordZonesOperation(recordZoneIDs: $0) }
            ?? .fetchAllRecordZonesOperation()
        var cloudKitError: Swift.Error?
        var results = [CKRecordZone.ID: CKRecordZone]()
        let semaphore = DispatchSemaphore(value: 0)
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        operation.fetchRecordZonesCompletionBlock = {
            results = $0 ?? [:]
            cloudKitError = $1
            semaphore.signal()
        }
        add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
        return results
    }
    
    func fetchZone(_ zone: CKRecordZone.ID) throws -> CKRecordZone {
        
        let zones = try fetchZones([zone])
        guard let value = zones[zone] else {
            assertionFailure("Missing zone value")
            throw CKError(.internalError)
        }
        return value
    }
    
    func modify(subscriptions save: [CKSubscription]?, delete: [CKSubscription.ID]? = nil) throws {
        
        let operation = CKModifySubscriptionsOperation(
            subscriptionsToSave: save,
            subscriptionIDsToDelete: delete
        )
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        var cloudKitError: Swift.Error?
        let semaphore = DispatchSemaphore(value: 0)
        operation.modifySubscriptionsCompletionBlock = { (_, _, error) in
            cloudKitError = error
            semaphore.signal()
        }
        add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
    }
}
