//
//  iCloud.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/25/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CloudKit
import CloudKitCodable
import KeychainAccess
import CoreLock

public final class CloudStore {
    
    public static let shared = CloudStore()
    
    deinit {
        
        #if os(iOS)
        if let observer = keyValueStoreObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        #endif
    }
    
    private init() {
        
        #if os(iOS)
        // observe changes
        keyValueStoreObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: self.keyValueStore,
            queue: nil,
            using: { [weak self] in self?.didChangeExternally($0) })
        #endif
    }
    
    // MARK: - Properties
    
    public var didChange: (() -> ())?
    
    private lazy var keychain = Keychain(service: .lockCloud, accessGroup: .lock).synchronizable(true)
    
    #if os(iOS)
    private lazy var keyValueStore: NSUbiquitousKeyValueStore = .default
    #endif
    
    private var keyValueStoreObserver: NSObjectProtocol?
    
    internal lazy var container: CKContainer = .lock
    
    // MARK: - Methods
    
    public func upload(applicationData: ApplicationData,
                       keys: [UUID: KeyData]) throws {
        
        // store lock private keys in iCloud keychain
        try keychain.removeAll()
        for (keyIdentifier, keyData) in keys {
            assert(applicationData[key: keyIdentifier] != nil, "Invalid key")
            try keychain.set(keyData.data, key: keyIdentifier.uuidString)
        }
        
        // get iCloud user
        var user = try CloudUser.fetch(in: container, database: .private)
        
        // upload configuration
        let cloudEncoder = CloudKitEncoder(context: container.privateCloudDatabase)
        user.applicationData = .init(applicationData) // set new application data
        let operation = try cloudEncoder.encode(user)
        operation.isAtomic = true
        var cloudKitError: Swift.Error?
        let semaphore = DispatchSemaphore(value: 0)
        operation.modifyRecordsCompletionBlock = { _,_,error in
            cloudKitError = error
            semaphore.signal()
        }
        container.privateCloudDatabase.add(operation)
        semaphore.wait()
        if let error = cloudKitError {
            throw error
        }
        
        // inform via key value store
        didUpload(applicationData: applicationData)
    }
    
    public func download() throws -> (applicationData: ApplicationData, keys: [UUID: KeyData])? {
        
        // get iCloud user
        let user = try CloudUser.fetch(in: container, database: .private)
        guard let cloudData = user.applicationData
            else { return nil }
        guard let applicationData = ApplicationData(cloudData) else {
            #if DEBUG
            dump(cloudData)
            assertionFailure("Could not initialize from iCloud")
            #endif
            return nil
        }
        
        // download keys from keychain
        var keys = [UUID: KeyData](minimumCapacity: applicationData.locks.count)
        for key in applicationData.keys {
            guard let data = try keychain.getData(key.identifier.uuidString),
                let keyData = KeyData(data: data)
                else { throw Error.missingKeychainItem(key.identifier) }
            keys[key.identifier] = keyData
        }
        
        return (applicationData, keys)
    }
    
    private func didUpload(applicationData: ApplicationData) {
        
        #if os(iOS)
        // inform iCloud Key Value Store
        keyValueStore.set(applicationData.updated as NSDate, forKey: UbiquitousKey.updated.rawValue)
        keyValueStore.synchronize()
        #elseif os(watchOS)
        
        #endif
    }
    
    #if os(iOS)
    public func lastUpdated() -> Date? {
        
        keyValueStore.synchronize()
        return keyValueStore.object(forKey: UbiquitousKey.updated.rawValue) as? Date
    }
    #endif
    
    #if os(iOS)
    private func didChangeExternally(_ notification: Notification) {
        
        keyValueStore.synchronize()
        didChange?()
    }
    #endif
}

public extension CloudStore {
    
    /// CloudStore Error
    enum Error: Swift.Error {
        
        /// Could not import due to missing KeyChain item.
        case missingKeychainItem(UUID)
    }
}

private extension CloudStore {
    
    enum KeyChainKey: String {
        
        case applicationData = "com.colemancda.Lock.ApplicationData"
    }
}

private extension Keychain {
    
    func set(_ value: Data, key: CloudStore.KeyChainKey) throws {
        try set(value, key: key.rawValue)
    }
    
    func getData(_ key: CloudStore.KeyChainKey) throws -> Data? {
        return try getData(key.rawValue)
    }
}

private extension CloudStore {
    
    enum UbiquitousKey: String {
        
        case updated
    }
}

internal extension ApplicationData {
    
    /// Attempt to update with no conflicts.
    func update(with applicationData: ApplicationData) -> ApplicationData? {
        
        // must be originally the same application data
        guard self.identifier == applicationData.identifier,
            self.created == applicationData.created
            else { return nil }
        
        // if local copy is newer, should not be overwritten with older copy.
        if self.locks != applicationData.locks {
            if self.keys != applicationData.keys {
                // overwrite with newer keys
                guard self.updated <= applicationData.updated
                    else { return nil }
                return applicationData
            } else {
                // no keys changed, keep newer local copy
                if self.updated <= applicationData.updated {
                    return applicationData
                } else {
                    return self
                }
            }
        } else {
            return applicationData
        }
    }
}

public extension Store {
    
    #if os(iOS)
    func cloudDidChangeExternally(retry: Bool = false) {
        
        if let lastUpdatedCloud = self.cloud.lastUpdated() {
            guard self.applicationData.updated < lastUpdatedCloud
                else { return }
        }
        
        if retry == false {
            log("☁️ iCloud changed externally")
        }
        
        DispatchQueue.cloud.async { [weak self] in
            guard let self = self else { return }
            var conflicts = false
            do {
                try self.syncCloud(conflicts: { _ in
                    conflicts = true
                    return nil
                })
            }
            catch { log("⚠️ Could not sync iCloud") }
            // sync again until data is no longer stale
            if conflicts == false,
                retry == false,
                let lastUpdatedCloud = self.cloud.lastUpdated(),
                self.applicationData.updated < lastUpdatedCloud {
                self.cloudDidChangeExternally(retry: true)
            }
        }
    }
    #endif
    
    func syncCloud(conflicts: (ApplicationData) -> Bool? = { _ in return nil }) throws {
        
        // make sure iCloud is enabled
        guard preferences.isCloudEnabled else { return }
        assert(Thread.isMainThread == false)
        guard try downloadCloud(conflicts: conflicts) else {
            DispatchQueue.main.async { [weak self] in
                self?.preferences.lastCloudUpdate = Date()
            }
            return
        } // aborted
        try uploadCloud()
        DispatchQueue.main.async { [weak self] in
            self?.preferences.lastCloudUpdate = Date()
        }
    }
    
    @discardableResult
    func downloadCloud(conflicts: (ApplicationData) -> Bool?) throws -> Bool {
        
        assert(Thread.isMainThread == false)
                
        guard let (cloudData, cloudKeys) = try cloud.download() else {
            log("☁️ No data in iCloud")
            return true
        }
        
        // Import private keys
        var newKeys = 0
        for (identifier, keyData) in cloudKeys {
            if self[key: identifier] == nil {
                self[key: identifier] = keyData
                newKeys += 1
            }
        }
        if newKeys > 0 {
            log("☁️ Imported \(newKeys) keys from iCloud")
        }
        
        // Import application data
        let oldApplicationData = self.applicationData
        guard cloudData != oldApplicationData else {
            log("☁️ No new data from iCloud")
            return false
        }
        
        #if DEBUG
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
        print("Cloud: \(cloudData.identifier) \(dateFormatter.string(from: cloudData.updated))")
        dump(cloudData)
        print("Local: \(oldApplicationData.identifier) \(dateFormatter.string(from: oldApplicationData.updated))")
        dump(oldApplicationData)
        #endif
        
        // attempt to overwrite
        if let newData = oldApplicationData.update(with: cloudData) {
            // write new application data
            self.applicationData = newData
            if newData != oldApplicationData {
                log("☁️ Updated application data from iCloud")
            } else {
                log("☁️ Keeping local data over iCloud")
            }
        } else if let shouldOverwrite = conflicts(cloudData) {
            // ask user to replace with conflicting data
            if shouldOverwrite {
                self.applicationData = cloudData
                log("☁️ Overriding application data from iCloud")
            } else {
                log("☁️ Discarding conflicting iCloud application data")
            }
        } else {
            log("☁️ Aborted iCloud download due to unresolved conflict")
            return false
        }
        self.applicationData.didUpdate() // define as latest
        // remove old keys
        var removedKeys = 0
        let newData = self.applicationData
        for oldKey in oldApplicationData.keys {
            // old key no longer exists
            if newData.keys.contains(oldKey) == false {
                // remove from keychain
                self[key: oldKey.identifier] = nil
                removedKeys += 1
            }
        }
        if removedKeys > 0 {
            log("☁️ Removed \(removedKeys) old keys from keychain")
        }
        log("☁️ Downloaded from iCloud")
        return true
    }
    
    func uploadCloud() throws {
                
        let applicationData = self.applicationData
        
        // read from to keychain
        var keys = [UUID: KeyData]()
        for key in applicationData.keys {
            let keyData = self[key: key.identifier]
            keys[key.identifier] = keyData
        }
        
        // upload keychain and application data to iCloud
        try cloud.upload(applicationData: applicationData, keys: keys)
        
        log("☁️ Uploaded to iCloud")
    }
}

public extension DispatchQueue {
    
    /// iCloud GCD Queue
    static var cloud: DispatchQueue {
        struct Cache {
            static let queue = DispatchQueue(label: "com.colemancda.Lock.iCloud")
        }
        return Cache.queue
    }
}

#if os(iOS)
import UIKit

public extension ActivityIndicatorViewController where Self: UIViewController {
    
    func syncCloud(showActivity: Bool) {
        
        assert(Thread.isMainThread)
        
        // TODO: check user preferences to prevent iCloud sync
        
        performActivity(showActivity: showActivity, queue: .cloud, { [weak self] in
            try Store.shared.syncCloud(conflicts: { self?.resolveCloudSyncConflicts($0) })
        }, completion: { (viewController, _) in
            
        })
    }
}

public extension UIViewController {
    
    func syncCloud() {
        
        assert(Thread.isMainThread)
        
        // TODO: check user preferences to prevent iCloud sync
        DispatchQueue.cloud.async {
            do {
                try Store.shared.syncCloud(conflicts: { [weak self] in
                    self?.resolveCloudSyncConflicts($0)
                })
            }
            catch { log("⚠️ Could not sync iCloud: \(error)") }
        }
    }
}

private extension UIViewController {
    
    func resolveCloudSyncConflicts(_ cloudData: ApplicationData) -> Bool? {
        
        assert(Thread.isMainThread == false)
        
        let semaphore = DispatchSemaphore(value: 0)
        var shouldOverwrite: Bool?
        var alertController: UIAlertController?
        mainQueue {
            
            let alert = UIAlertController(
                title: "Conflicting iCloud Data",
                message: "Overwrite from iCloud data?",
                preferredStyle: .alert
            )
            alertController = alert
            alert.addAction(UIAlertAction(title: "Discard", style: .`default`, handler: { (UIAlertAction) in
                shouldOverwrite = false
                semaphore.signal()
                alert.presentingViewController?.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Overwrite", style: .`default`, handler: { (UIAlertAction) in
                shouldOverwrite = true
                semaphore.signal()
                alert.presentingViewController?.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        let _ = semaphore.wait(timeout: .now() + 30.0)
        if shouldOverwrite == nil {
            mainQueue {
                alertController?.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
        return shouldOverwrite
    }
}
#endif

// MARK: - CloudKit Extensions

/// UbiquityContainerIdentifier
///
/// iCloud Identifier
public enum UbiquityContainerIdentifier: String {
    
    case lock = "iCloud.com.colemancda.Lock"
}

public extension FileManager {
    
    /**
     Returns the URL for the iCloud container associated with the specified identifier and establishes access to that container.
     
     - Note: Do not call this method from your app’s main thread. Because this method might take a nontrivial amount of time to set up iCloud and return the requested URL, you should always call it from a secondary thread.
     */
    func ubiquityContainerURL(for identifier: UbiquityContainerIdentifier) -> URL? {
        assert(Thread.isMainThread == false, "Use iCloud from secondary thread")
        return url(forUbiquityContainerIdentifier: identifier.rawValue)
    }
}

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

public extension CKContainer {
    
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
