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
    
    // MARK: - Initialization
    
    public init(url: URL) async throws {
        self.file = try await JSONFile(url: url, defaultValue: Database())
    }
    
    // MARK: - Accessors
    
    private var database: Database {
        get async {
            await file.value
        }
    }
    
    public var url: URL {
        return file.url
    }
    
    public var isEmpty: Bool {
        get async {
            let keysEmpty = await database.keys.isEmpty
            let newKeysEmpty = await database.newKeys.isEmpty
            return keysEmpty && newKeysEmpty
        }
    }
    
    public var list: KeysList {
        get async {
            await KeysList(
                keys: database.keys.map { $0.key },
                newKeys: database.newKeys.map { $0.newKey }
            )
        }
    }
    
    // MARK: - Methods
    
    public func add(_ key: Key, secret: KeyData) async throws {
        try await write {
            $0.keys.append(Database.KeyEntry(key: key, secret: secret))
        }
    }
    
    public func key(for id: UUID) async throws -> (key: Key, secret: KeyData)? {
        
        guard let keyEntry = await database.keys.first(where: { $0.key.id == id })
            else { return nil }
        
        return (keyEntry.key, keyEntry.secret)
    }
    
    public func add(_ key: NewKey, secret: KeyData) async throws {
        try await write {
            $0.newKeys.append(Database.NewKeyEntry(newKey: key, secret: secret))
        }
    }
    
    public func newKey(for id: UUID) async throws -> (newKey: NewKey, secret: KeyData)? {

        guard let keyEntry = await database.newKeys.first(where: { $0.newKey.id == id })
            else { return nil }
        
        return (keyEntry.newKey, keyEntry.secret)
    }
    
    public func removeKey(_ id: UUID) async throws {
        try await write {
            $0.keys.removeAll(where: { $0.key.id == id })
        }
    }
    
    public func removeNewKey(_ id: UUID) async throws {
        
        try await write {
            $0.newKeys.removeAll(where: { $0.newKey.id == id })
        }
    }
    
    public func removeAll() async throws {
        
        try await write {
            $0.keys.removeAll()
            $0.newKeys.removeAll()
        }
    }
    
    private func write(
        database changes: (inout Database) -> ()
    ) async throws {
        
        var database = await self.database
        changes(&database)
        try await file.write(database)
    }
}

extension AuthorizationStoreFile: CustomStringConvertible {
    
    public var description: String {
        return "<AuthorizationStoreFile: \(ObjectIdentifier(self)) url:\(url)>"
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
