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
    
    public func add(_ key: NewKey, secret: KeyData) throws {
        
        try write { $0.newKeys.append(Database.NewKeyEntry(newKey: key, secret: secret)) }
    }
    
    public func newKey(for identifier: UUID) throws -> (newKey: NewKey, secret: KeyData)? {

        guard let keyEntry = database.newKeys.first(where: { $0.newKey.identifier == identifier })
            else { return nil }
        
        return (keyEntry.newKey, keyEntry.secret)
    }
    
    public var list: KeysList {
        
        return KeysList(
            keys: database.keys.map { $0.key },
            newKeys: database.newKeys.map { $0.newKey }
        )
    }
    
    private func write(database changes: (inout Database) -> ()) throws {
        
        var database = self.database
        changes(&database)
        try file.write(database)
    }
}

extension AuthorizationStoreFile: CustomStringConvertible {
    
    public var description: String {
        return "<AuthorizationStoreFile: \(ObjectIdentifier(self)) url:\(url) keys:\(database.keys.count) newKeys:\(database.newKeys.count)>"
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
        
        let newKey: NewKey
        let secret: KeyData
    }
}
