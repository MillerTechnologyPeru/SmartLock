//
//  AuthorizationStoreFile.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/13/18.
//
//


import Foundation
import CoreLock

public final class AuthorizationStoreFile: LockAuthorizationStore {
    
    // MARK: - Properties
    
    public let url: URL
    
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    
    private var database = Database()
    
    public init(url: URL) {
        
        self.url = url
        
        // attempt to load previous value.
        loadData()
    }
    
    // MARK: - Methods
    
    public var isEmpty: Bool {
        
        return database.keys.isEmpty
            && database.newKeys.isEmpty
    }
    
    public func add(_ key: Key, secret: KeyData) throws {
        
        try write { $0.keys.append(Database.KeyEntry(key: key, secret: secret)) }
    }
    
    public func key(for identifier: UUID) throws -> (key: Key, secret: KeyData)? {
        
        guard let keyEntry = database.keys.first(where: { $0.key.identifier == identifier })
            else { return nil }
        
        return (keyEntry.key, keyEntry.secret)
    }
    
    private func loadData() {
        
        guard let data = try? Data(contentsOf: url),
            let database = try? jsonDecoder.decode(Database.self, from: data)
            else { return }
        
        self.database = database
    }
    
    private func write(database changes: (inout Database) -> ()) throws {
        
        var database = self.database
        
        changes(&database)
        
        let data = try jsonEncoder.encode(database)
        
        try data.write(to: url, options: .atomic)
        
        self.database = database
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
