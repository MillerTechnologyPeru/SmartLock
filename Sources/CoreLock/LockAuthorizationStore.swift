//
//  LockAuthorizationStore.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation

/// Lock Authorization Store
public protocol LockAuthorizationStore: AnyObject {
    
    var isEmpty: Bool { get }
    
    func add(_ key: Key, secret: KeyData) throws
    
    func key(for id: UUID) throws -> (key: Key, secret: KeyData)?
    
    func add(_ key: NewKey, secret: KeyData) throws
    
    func newKey(for id: UUID) throws -> (newKey: NewKey, secret: KeyData)?
    
    func removeKey(_ id: UUID) throws
    
    func removeNewKey(_ id: UUID) throws
    
    func removeAll() throws
    
    var list: KeysList { get }
}

// MARK: - Supporting Types

public final class InMemoryLockAuthorization: LockAuthorizationStore {
    
    public init() { }
    
    private var keys = [KeyEntry]()
    
    private var newKeys = [NewKeyEntry]()
    
    public var isEmpty: Bool {
        
        return keys.isEmpty && newKeys.isEmpty
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
