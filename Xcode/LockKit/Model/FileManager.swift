//
//  FileManager.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock

public extension FileManager {
    
    /// Returns the container directory associated with the specified security application group identifier.
    func containerURL(for appGroup: AppGroup) -> URL? {
        return containerURL(forSecurityApplicationGroupIdentifier: appGroup.rawValue)
    }
    
    var cachesDirectory: URL? {
        return urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    
    var documentsURL: URL? {
        return urls(for: .documentDirectory, in: .userDomainMask).first
    }
}

public extension FileManager {
    
    /// Access shared files in the Lock app group.
    final class Lock {
        
        // MARK: - Initialization
        
        public static let shared = FileManager.Lock()
        
        private init() { }
        
        // MARK: - Properties
        
        private let jsonDecoder = JSONDecoder()
        
        private let jsonEncoder = JSONEncoder()
        
        private lazy var fileManager = FileManager()
        
        private lazy var containerURL: URL = {
            #if os(tvOS)
            guard let containerURL = fileManager.cachesDirectory
                else { fatalError("Could not open Caches directory"); }
            #else
            guard let containerURL = fileManager.containerURL(for: AppGroup.lock)
                else { fatalError("Could not open App Group directory"); }
            #endif
            return containerURL
        }()
        
        // MARK: - Methods
        
        public lazy var documentURL: URL = {
            guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
                else { fatalError() }
            return url
        }()
        
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

public extension FileManager.Lock {
        
    var applicationData: ApplicationData? {
        
        get { return read(ApplicationData.self, from: .applicationData) }
        set { write(newValue, file: .applicationData) }
    }
}

private extension FileManager.Lock {
    
    func read <T: Decodable> (_ type: T.Type, from file: File) -> T? {
        
        guard let data = read(file: file)
            else { return nil }
        do { return try jsonDecoder.decode(type, from: data) }
        catch {
            try? fileManager.removeItem(at: url(for: file))
            #if DEBUG
            print(error)
            assertionFailure("Could not decode \(type) from \(file.rawValue)")
            #endif
            return nil
        }
    }
    
    func write <T: Encodable> (_ value: T?, file: File) {
        
        guard let value = value else {
            do { try fileManager.removeItem(at: url(for: file)) }
            catch {
                #if DEBUG
                print(error)
                assertionFailure("Could not remove \(file.rawValue)")
                #endif
            }
            return
        }
        
        do {
            let data = try jsonEncoder.encode(value)
            try write(data, to: file)
        } catch {
            #if DEBUG
            print(error)
            assertionFailure("Could not encode \(T.self) to \(file.rawValue)")
            #endif
        }
        
        log("🗄️ Wrote file \(file.rawValue)")
    }
}

public extension FileManager.Lock {
    
    enum File: String {
        
        case applicationData = "data.json"
    }
}
