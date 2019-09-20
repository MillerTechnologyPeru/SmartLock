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
}

internal extension CKDatabase {
    
    @discardableResult
    func fetch(_ operation: CKFetchRecordsOperation) throws -> [CKRecord.ID: CKRecord] {
        
        var cloudKitError: Swift.Error?
        var recordsByRecordID = [CKRecord.ID: CKRecord]()
        let semaphore = DispatchSemaphore(value: 0)
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
    
    @discardableResult
    func modify(_ operation: CKModifyRecordsOperation) throws -> (saved: [CKRecord], deleted: [CKRecord.ID]) {
        
        var cloudKitError: Swift.Error?
        var saved = [CKRecord]()
        var deleted = [CKRecord.ID]()
        let semaphore = DispatchSemaphore(value: 0)
        operation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecords, error) in
            cloudKitError = error
            saved = savedRecords ?? []
            deleted = deletedRecords ?? []
            semaphore.signal()
        }
        add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
        return (saved, deleted)
    }
    
    @discardableResult
    func query(_ operation: CKQueryOperation,
               record: @escaping (CKRecord) throws -> (Bool)) throws -> CKQueryOperation.Cursor? {
        
        var cursor: CKQueryOperation.Cursor?
        var cloudKitError: Swift.Error?
        let semaphore = DispatchSemaphore(value: 0)
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
                  record: @escaping (CKRecord) throws -> (Bool)) throws {
        
        var cursor = try self.query(.init(query: query), record: record)
        while let queryCursor = cursor {
            cursor = try self.query(.init(cursor: queryCursor), record: record)
        }
    }
}
