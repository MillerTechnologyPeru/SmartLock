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
    
    func fetchUserRecordID() async throws -> CKRecord.ID {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchUserRecordID { (id, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let id = id {
                    continuation.resume(returning: id)
                } else {
                    assertionFailure()
                    continuation.resume(throwing: CKError(.internalError))
                }
            }
        }
    }
    
    #if !os(tvOS)
    @available(tvOS, unavailable)
    func discoverAllUserIdentities() -> AsyncThrowingStream<CKUserIdentity, Error> {
        return .init(CKUserIdentity.self, bufferingPolicy: .unbounded) { continuation in
            let operation = CKDiscoverAllUserIdentitiesOperation()
            operation.configuration.isLongLived = false
            operation.configuration.allowsCellularAccess = true
            operation.configuration.qualityOfService = .userInitiated
            operation.userIdentityDiscoveredBlock = {
                continuation.yield($0)
            }
            operation.discoverAllUserIdentitiesResultBlock = {
                switch $0 {
                case .success:
                    continuation.finish()
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            add(operation)
        }
    }
    #endif
    
    func discoverUserIdentities(
        _ userIdentityLookupInfos: [CKUserIdentity.LookupInfo]
    )  -> AsyncThrowingStream<(CKUserIdentity, CKUserIdentity.LookupInfo), Error> {
        return AsyncThrowingStream<(CKUserIdentity, CKUserIdentity.LookupInfo), Error>((CKUserIdentity, CKUserIdentity.LookupInfo).self, bufferingPolicy: .unbounded) { continuation in
            let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: userIdentityLookupInfos)
            operation.configuration.isLongLived = false
            operation.configuration.allowsCellularAccess = true
            operation.configuration.qualityOfService = .userInitiated
            operation.userIdentityDiscoveredBlock = {
                continuation.yield(($0, $1))
            }
            operation.discoverUserIdentitiesResultBlock = {
                switch $0 {
                case .success:
                    continuation.finish()
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            add(operation)
        }
    }
    
    func fetchShareParticipants(
        _ userIdentityLookupInfos: [CKUserIdentity.LookupInfo]
    ) -> AsyncThrowingStream<(CKUserIdentity.LookupInfo, CKShare.Participant), Error> {
        return AsyncThrowingStream<(CKUserIdentity.LookupInfo, CKShare.Participant), Error>((CKUserIdentity.LookupInfo, CKShare.Participant).self, bufferingPolicy: .unbounded) { continuation in
            let operation = CKFetchShareParticipantsOperation(userIdentityLookupInfos: userIdentityLookupInfos)
            operation.configuration.isLongLived = false
            operation.configuration.allowsCellularAccess = true
            operation.configuration.qualityOfService = .userInitiated
            operation.perShareParticipantResultBlock = {
                switch $1 {
                case let .success(value):
                    continuation.yield(($0, value))
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            operation.fetchShareParticipantsResultBlock = {
                switch $0 {
                case .success:
                    continuation.finish()
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            add(operation)
        }
    }
    
    func fetchShareParticipant(
        _ userIdentity: CKUserIdentity.LookupInfo
    ) async throws -> CKShare.Participant {
        let stream = fetchShareParticipants([userIdentity])
        guard let foundUser = try await stream.first(where: { $0.0 == userIdentity })?.1 else {
            assertionFailure("Expected a participant")
            throw CKError(.internalError)
        }
        return foundUser
    }
    
    /// An operation that fetches shared record metadata for one or more shares.
    func fetchShareMetadata(
        for shareURLs: [URL],
        shouldFetchRootRecord: Bool = false
    ) -> AsyncThrowingStream<(URL, CKShare.Metadata), Error> {
        return AsyncThrowingStream<(URL, CKShare.Metadata), Error>.init((URL, CKShare.Metadata).self, bufferingPolicy: .unbounded) { continuation in
            let operation = CKFetchShareMetadataOperation(shareURLs: shareURLs)
            operation.configuration.isLongLived = false
            operation.configuration.allowsCellularAccess = true
            operation.configuration.qualityOfService = .userInitiated
            operation.shouldFetchRootRecord = shouldFetchRootRecord
            operation.perShareMetadataResultBlock = {
                switch $1 {
                case let .success(value):
                    continuation.yield(($0, value))
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            operation.fetchShareMetadataResultBlock = {
                switch $0 {
                case .success:
                    continuation.finish()
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            add(operation)
        }
    }
    
    func acceptShares(_ shares: [CKShare.Metadata]) -> AsyncThrowingStream<(CKShare.Metadata, CKShare), Error> {
        return AsyncThrowingStream<(CKShare.Metadata, CKShare), Error>.init((CKShare.Metadata, CKShare).self, bufferingPolicy: .unbounded) { continuation in
            let operation = CKAcceptSharesOperation(shareMetadatas: shares)
            operation.configuration.isLongLived = false
            operation.configuration.allowsCellularAccess = true
            operation.configuration.qualityOfService = .userInitiated
            operation.perShareResultBlock = {
                switch $1 {
                case let .success(value):
                    continuation.yield(($0, value))
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            operation.acceptSharesResultBlock = {
                switch $0 {
                case .success:
                    continuation.finish()
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            add(operation)
        }
    }
}

internal extension CKDatabase {
    
    @discardableResult
    func fetch(_ operation: CKFetchRecordsOperation) -> AsyncThrowingStream<CKRecord, Error> {
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        return AsyncThrowingStream<CKRecord, Error>(CKRecord.self, bufferingPolicy: .unbounded) { continuation in
            operation.perRecordResultBlock = {
                switch $1 {
                case let .success(value):
                    continuation.yield(value)
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            operation.fetchRecordsResultBlock = {
                switch $0 {
                case .success:
                    continuation.finish()
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            add(operation)
        }
    }
    
    func modify(_ operation: CKModifyRecordsOperation) async throws {
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = {
                continuation.resume(with: $0)
            }
            add(operation)
            return
        }
    }
    
    func query(
        _ operation: CKQueryOperation
    ) -> AsyncThrowingStream<CKQueryOperation.AsyncStreamValue, Swift.Error> {
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        return .init(CKQueryOperation.AsyncStreamValue.self, bufferingPolicy: .unbounded) { continuation in
            
            operation.recordMatchedBlock = { (id, result) in
                switch result {
                case let .success(value):
                    continuation.yield(.record(value))
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            
            operation.queryResultBlock = { (result) in
                switch result {
                case let .success(value):
                    if let cursor = value {
                        continuation.yield(.cursor(cursor))
                    }
                    continuation.finish()
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            
            add(operation)
        }
    }
    
    func queryAll(
        _ query: CKQuery,
        zone: CKRecordZone.ID? = nil
    ) -> AsyncThrowingStream<CKRecord, Swift.Error> {
        let operation = CKQueryOperation(query: query)
        operation.zoneID = zone
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        return AsyncThrowingStream(CKRecord.self, bufferingPolicy: .unbounded) { (continuation: AsyncThrowingStream<CKRecord, Swift.Error>.Continuation) in
            do {
                let task = Task.detached {
                    do {
                        var cursor: CKQueryOperation.Cursor?
                        // first request
                        for try await value in self.query(operation) {
                            switch value {
                            case let .record(record):
                                continuation.yield(record)
                            case let .cursor(newCursor):
                                cursor = newCursor
                            }
                        }
                        
                        // continue fetching if cursor returned
                        while let queryCursor = cursor {
                            let cursorOperation = CKQueryOperation(cursor: queryCursor)
                            cursorOperation.zoneID = zone
                            for try await value in self.query(cursorOperation) {
                                switch value {
                                case let .record(record):
                                    continuation.yield(record)
                                case let .cursor(newCursor):
                                    cursor = newCursor
                                }
                            }
                        }
                        
                        // end stream
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                /*
                continuation.onTermination = {
                    task.cancel()
                }*/
            }
            return
        }
    }
    
    func modifyZones(
        save: [CKRecordZone]?,
        delete: [CKRecordZone.ID]? = nil
    ) async throws {
        let operation = CKModifyRecordZonesOperation(
            recordZonesToSave: save,
            recordZoneIDsToDelete: delete
        )
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordZonesResultBlock = {
                continuation.resume(with: $0)
            }
            add(operation)
        }
    }
    
    func fetchZones(
        _ zones: [CKRecordZone.ID]? = nil
    ) -> AsyncThrowingStream<CKRecordZone, Error> {
        let operation = zones.flatMap { CKFetchRecordZonesOperation(recordZoneIDs: $0) }
            ?? .fetchAllRecordZonesOperation()
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        return .init(CKRecordZone.self, bufferingPolicy: .unbounded) { continuation in
            operation.perRecordZoneResultBlock = {
                switch $1 {
                case let .success(value):
                    continuation.yield(value)
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            operation.fetchRecordZonesResultBlock = {
                switch $0 {
                case .success:
                    continuation.finish()
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            add(operation)
        }
    }
    
    func fetchZone(_ zone: CKRecordZone.ID) async throws -> CKRecordZone {
        guard let zone = try await fetchZones([zone]).first(where: { $0.zoneID == zone }) else {
            assertionFailure("Expected a matching zone")
            throw CKError(.internalError)
        }
        return zone
    }
    
    func modify(
        subscriptions save: [CKSubscription]?,
        delete: [CKSubscription.ID]? = nil
    ) async throws {
        let operation = CKModifySubscriptionsOperation(
            subscriptionsToSave: save,
            subscriptionIDsToDelete: delete
        )
        operation.configuration.isLongLived = false
        operation.configuration.allowsCellularAccess = true
        operation.configuration.qualityOfService = .userInitiated
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifySubscriptionsResultBlock = {
                continuation.resume(with: $0)
            }
            add(operation)
        }
    }
}

internal extension CKQueryOperation {
    
    enum AsyncStreamValue {
        case record(CKRecord)
        case cursor(CKQueryOperation.Cursor)
    }
}
