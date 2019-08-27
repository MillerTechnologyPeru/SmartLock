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
    
    public static let shared = CloudStore(identifier: .lock)
    
    internal init(identifier: UbiquityContainerIdentifier) {
        self.identifier = identifier
    }
    
    // MARK: - Properties
    
    public let identifier: UbiquityContainerIdentifier
    
    public var cloudChanged: (() -> ())?
    
    private lazy var fileManager = FileManager()
    
    private lazy var keychain = Keychain(service: .lockCloud).synchronizable(true)
    
    // MARK: - Methods
    
    public func upload(applicationData: ApplicationData,
                       keys: [UUID: KeyData]) throws {
        
        // store lock private keys in keychain
        for (keyIdentifier, keyData) in keys {
            assert(applicationData.keys.lazy.map({ $0.identifier }).contains(keyIdentifier), "Invalid key")
            try keychain.set(keyData.data, key: keyIdentifier.uuidString)
        }
        
        // upload configuration file
        let data = applicationData.encodeJSON()
        try write(data, to: .applicationData)
    }
    
    public func download() throws -> (applicationData: ApplicationData, keys: [UUID: KeyData])? {
        
        guard let jsonData = try read(file: .applicationData)
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
    
    private func containerURL() throws -> URL {
        guard let containerURL = fileManager.ubiquityContainerURL(for: .lock)
            else { throw Error.missingCloudAccount }
        return containerURL
    }
    
    private func url(for file: File) throws -> URL {
        return try containerURL().appendingPathComponent(file.rawValue)
    }
    
    private func read(file: File) throws -> Data? {
        let url = try self.url(for: file)
        return try? Data(contentsOf: url, options: [.mappedIfSafe])
    }
    
    private func write(_ data: Data, to file: File) throws {
        let url = try self.url(for: file)
        try data.write(to: url, options: [.atomicWrite])
    }
}

public extension CloudStore {
    
    /// CloudStore Error
    enum Error: Swift.Error {
        
        /// Not signed in to iCloud.
        case missingCloudAccount
        
        /// Could not import due to missing KeyChain item.
        case missingKeychainItem(UUID)
    }
}

private extension CloudStore {
    
    enum File: String {
        
        case applicationData = "data.json"
    }
}

internal extension ApplicationData {
    
    /// Attempt to update with no conflicts.
    func canUpdate(with applicationData: ApplicationData) -> Bool {
        
        // must be originally the same application data
        guard self.identifier == applicationData.identifier,
            self.created == applicationData.created
            else { return false }
        
        // if local copy is newer, should not be overwritten with older copy.
        guard self.updated < applicationData.updated
            else { return false }
        
        return true
    }
}

public extension Store {
    
    func syncCloud(_ cloud: CloudStore = .shared,
                   conflicts: (ApplicationData) -> Bool? = { _ in return nil }) throws {
        
        assert(Thread.isMainThread == false)
        
        guard try downloadCloud(cloud: cloud, conflicts: conflicts)
            else { return } // aborted
        try uploadCloud()
    }
    
    @discardableResult
    func downloadCloud(cloud: CloudStore = .shared, conflicts: (ApplicationData) -> Bool?) throws -> Bool {
        
        assert(Thread.isMainThread == false)
        
        log("☁️ Downloading from iCloud")
        
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
            return true
        }
        
        // attempt to overwrite
        if oldApplicationData.canUpdate(with: cloudData) {
            // write new application data
            self.applicationData = cloudData
            log("☁️ Updated application data from iCloud")
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
        return true
    }
    
    func uploadCloud(cloud: CloudStore = .shared) throws {
        
        log("☁️ Uploading to iCloud")
        
        let applicationData = self.applicationData
        
        // read from to keychain
        var keys = [UUID: KeyData]()
        for key in applicationData.keys {
            let keyData = self[key: key.identifier]
            keys[key.identifier] = keyData
        }
        
        // upload keychain and application data to iCloud
        try cloud.upload(applicationData: applicationData, keys: keys)
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
    
    func syncCloud(showProgressHUD: Bool = true) {
        
        assert(Thread.isMainThread)
        
        // TODO: check user preferences to prevent iCloud sync
        
        performActivity(showProgressHUD: showProgressHUD, queue: .cloud, { [weak self] in
            try Store.shared.syncCloud(conflicts: { self?.resolveCloudSyncConflicts($0) })
        }, completion: { (viewController, _) in
            
        })
    }
    
    private func resolveCloudSyncConflicts(_ cloudData: ApplicationData) -> Bool? {
        
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
