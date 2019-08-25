//
//  iCloud.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/25/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

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
        
        // MARK: - Properties
        
        private let jsonDecoder = JSONDecoder()
        
        private let jsonEncoder = JSONEncoder()
        
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
