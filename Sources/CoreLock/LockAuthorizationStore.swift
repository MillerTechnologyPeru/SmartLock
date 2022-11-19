//
//  LockAuthorizationStore.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation

/// Lock Authorization Store
public protocol LockAuthorizationStore: AnyObject {
    
    var isEmpty: Bool { get async }
    
    func add(_ key: Key, secret: KeyData) async throws
    
    func key(for id: UUID) async throws -> (key: Key, secret: KeyData)?
    
    func add(_ key: NewKey, secret: KeyData) async throws
    
    func newKey(for id: UUID) async throws -> (newKey: NewKey, secret: KeyData)?
    
    func removeKey(_ id: UUID) async throws
    
    func removeNewKey(_ id: UUID) async throws
    
    func removeAll() async throws
    
    var list: KeysList { get async }
}

// MARK: - Supporting Types

public actor InMemoryLockAuthorization: LockAuthorizationStore {
    
    public init() { }
    
    private var keys = [KeyEntry]()
    
    private var newKeys = [NewKeyEntry]()
    
    nonisolated public var isEmpty: Bool {
        get async {
            let keysEmpty = await keys.isEmpty
            let newKeysEmpty = await newKeys.isEmpty
            return keysEmpty && newKeysEmpty
        }
    }
    
    public func add(_ key: Key, secret: KeyData) throws {
        keys.append(KeyEntry(key: key, secret: secret))
    }
    
    public func key(for id: UUID) throws -> (key: Key, secret: KeyData)? {
        guard let keyEntry = keys.first(where: { $0.key.id == id })
            else { return nil }
        return (keyEntry.key, keyEntry.secret)
    }
    
    public func add(_ key: NewKey, secret: KeyData) throws {
        newKeys.append(NewKeyEntry(newKey: key, secret: secret))
    }
    
    public func newKey(for id: UUID) throws -> (newKey: NewKey, secret: KeyData)? {
        guard let keyEntry = newKeys.first(where: { $0.newKey.id == id })
            else { return nil }
        return (keyEntry.newKey, keyEntry.secret)
    }
    
    public func removeKey(_ id: UUID) throws {
        keys.removeAll(where: { $0.key.id == id })
    }
    
    public func removeNewKey(_ id: UUID) throws {
        newKeys.removeAll(where: { $0.newKey.id == id })
    }
    
    public func removeAll() throws {
        keys.removeAll()
        newKeys.removeAll()
    }
    
    public var list: KeysList {
        
        return KeysList(
            keys: keys.map { $0.key },
            newKeys: newKeys.map { $0.newKey }
        )
    }
}

private extension InMemoryLockAuthorization {
    
    struct KeyEntry {
        
        let key: Key
        
        let secret: KeyData
    }
    
    struct NewKeyEntry {
        
        let newKey: NewKey
        
        let secret: KeyData
    }
}
