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
    
    case lock = "com.colemancda.Lock"
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

public extension FileManager {
    
    /// Access files stored in iCloud.
    final class Cloud {
        
        // MARK: - Initialization
        
        public static let shared = FileManager.Cloud()
        
        private init() { }
        
        // MARK: - Properties
        
        private lazy var fileManager = FileManager()
        
        private lazy var containerURL: URL = {
            guard let containerURL = fileManager.ubiquityContainerURL(for: .lock)
                else { fatalError("Could not open App Group directory"); }
            return containerURL
        }()
        
        // MARK: - Methods
        
        public func url(for file: File) -> URL {
            return containerURL.appendingPathComponent(file.rawValue)
        }
        
        public func read(file: File) -> Data? {
            return try? Data(contentsOf: url(for: file), options: [.mappedIfSafe])
        }
        
        public func write(_ data: Data, to file: File) throws {
            try data.write(to: url(for: file), options: [.atomicWrite])
        }
    }
}

public extension FileManager.Cloud {
    
    enum File: String {
        
        case applicationData = "data.json"
    }
}

public final class CloudStore {
    
    public static let shared = CloudStore()
    
    private init() { }
    
    private lazy var fileManager: FileManager.Cloud = .shared
    
    private lazy var keychain = Keychain(service: .lockCloud).synchronizable(true)
    
    public func upload(applicationData: ApplicationData,
                       keys: [UUID: KeyData]) throws {
        
        // store lock private keys in keychain
        for (keyIdentifier, keyData) in keys {
            assert(applicationData.keys.lazy.map({ $0.identifier }).contains(keyIdentifier), "Invalid key")
            try keychain.set(keyData.data, key: keyIdentifier.uuidString)
        }
        
        // upload configuration file
        let data = applicationData.encodeJSON()
        try fileManager.write(data, to: .applicationData)
    }
    
    public func download() throws -> (applicationData: ApplicationData, keys: [UUID: KeyData])? {
        
        guard let jsonData = fileManager.read(file: .applicationData)
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
}

public extension CloudStore {
    
    /// CloudStore Error
    enum Error: Swift.Error {
        
        ///
        case missingKeychainItem(UUID)
    }
}
