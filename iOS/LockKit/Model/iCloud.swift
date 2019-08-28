//
//  iCloud.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/25/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CloudKit
import KeychainAccess
import CoreLock

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

public final class CloudStore {
    
    public static let shared = CloudStore()
    
    deinit {
        
        if let observer = keyValueStoreObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private init() {
        
        // observe changes
        keyValueStoreObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: self.keyValueStore,
            queue: nil,
            using: { [weak self] in self?.didChangeExternally($0) })
    }
    
    // MARK: - Properties
    
    public var didChange: (() -> ())?
    
    private lazy var keychain = Keychain(service: .lockCloud, accessGroup: .lock).synchronizable(true)
    
    private lazy var keyValueStore: NSUbiquitousKeyValueStore = .default
    
    private var keyValueStoreObserver: NSObjectProtocol?
        
    // MARK: - Methods
    
    public func upload(applicationData: ApplicationData,
                       keys: [UUID: KeyData]) throws {
        
        // store lock private keys in keychain
        try keychain.removeAll()
        for (keyIdentifier, keyData) in keys {
            assert(applicationData[key: keyIdentifier] != nil, "Invalid key")
            try keychain.set(keyData.data, key: keyIdentifier.uuidString)
        }
        
        // upload configuration file
        let data = applicationData.encodeJSON()
        try keychain.set(data, key: .applicationData)
        
        // inform via key value store
        didUpload(applicationData: applicationData)
    }
    
    public func download() throws -> (applicationData: ApplicationData, keys: [UUID: KeyData])? {
        
        guard let jsonData = try keychain.getData(.applicationData)
            else { return nil }
        
        let applicationData = try ApplicationData.decodeJSON(from: jsonData)
        
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
        
        // inform iCloud Key Value Store
        keyValueStore.set(applicationData.updated as NSDate, forKey: UbiquitousKey.updated.rawValue)
        keyValueStore.synchronize()
    }
    
    public func lastUpdated() -> Date? {
        
        keyValueStore.synchronize()
        return keyValueStore.object(forKey: UbiquitousKey.updated.rawValue) as? Date
    }
    
    private func didChangeExternally(_ notification: Notification) {
        
        keyValueStore.synchronize()
        didChange?()
    }
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
    
    func syncCloud(conflicts: (ApplicationData) -> Bool? = { _ in return nil }) throws {
        
        assert(Thread.isMainThread == false)
        
        guard try downloadCloud(conflicts: conflicts)
            else { return } // aborted
        try uploadCloud()
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
    
    static var cloud: DispatchQueue {
        struct Cache {
            static let queue = DispatchQueue(label: "com.colemancda.Lock.iCloud")
        }
        return Cache.queue
    }
}

#if canImport(UIKit)
import UIKit

public extension ActivityIndicatorViewController where Self: UIViewController {
    
    func syncCloud(showProgressHUD: Bool) {
        
        assert(Thread.isMainThread)
        
        // TODO: check user preferences to prevent iCloud sync
        
        performActivity(showProgressHUD: showProgressHUD, queue: .cloud, { [weak self] in
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
