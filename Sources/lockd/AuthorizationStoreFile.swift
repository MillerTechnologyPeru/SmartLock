//
//  AuthorizationStoreFile.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/13/18.
//
//


import Foundation
import CoreLock
import CoreLockGATTServer

public final class AuthorizationStoreFile: LockAuthorizationStore {
    
    // MARK: - Properties
    
    private let file: JSONFile<Database>
    
    private var database: Database {
        return file.value
    }
    
    public var url: URL {
        return file.url
    }
    
    public var isEmpty: Bool {
        
        return database.keys.isEmpty
            && database.newKeys.isEmpty
    }
    
    public var keysCount: Int {
        return database.keys.count
    }
    
    public var newKeysCount: Int {
        return database.newKeys.count
    }
    
    // MARK: - Initialization
    
    public init(url: URL) throws {
        
        self.file = try JSONFile(url: url, defaultValue: Database())
    }
    
    // MARK: - Methods
    
    public func add(_ key: Key, secret: KeyData) throws {
        
        try write { $0.keys.append(Database.KeyEntry(key: key, secret: secret)) }
    }
    
    public func key(for identifier: UUID) throws -> (key: Key, secret: KeyData)? {
        
        guard let keyEntry = database.keys.first(where: { $0.key.identifier == identifier })
            else { return nil }
        
        return (keyEntry.key, keyEntry.secret)
    }
    
    private func write(database changes: (inout Database) -> ()) throws {
        
        var database = self.database
        changes(&database)
        try file.write(database)
    }
    
    /// Dump the database
    public func dump() -> String {
        
        var string = ""
        Swift.dump(database, to: &string)
        return string
    }
}

extension AuthorizationStoreFile: CustomStringConvertible {
    
    public var description: String {
        return "<AuthorizationStoreFile: \(ObjectIdentifier(self)) url:\(url) keys:\(keysCount) newKeys:\(newKeysCount)>"
    }
}

extension AuthorizationStoreFile: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return """
        \(url)
        \(dump())
        """
    }
}

// MARK: - Supporting Types

private extension AuthorizationStoreFile {
    
    struct Database: Codable, Equatable {
        
        var keys: [KeyEntry]
        
        var newKeys: [NewKeyEntry]
        
        init() {
            
            self.keys = []
            self.newKeys = []
        }
    }
}

extension AuthorizationStoreFile.Database {
    
    struct KeyEntry: Codable, Equatable {
        
        let key: Key
        let secret: KeyData
    }
    
    struct NewKeyEntry: Codable, Equatable {
        
        /// New key
        let newKey: Key
        
        /// Shared secret used for onboarding
        let sharedSecret: KeyData
    }
}
