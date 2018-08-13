//
//  Store.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock

#if os(iOS)
import KeychainAccess
#endif

public final class Store {
    
    public static let shared = Store()
    
    private init() {
        
        loadCache()
    }
    
    private let defaults = Defaults.shared
    
    private let keychain = Keychain()
    
    private let storageKey = DefaultsKey<[UUID: LockCache]>("locks")

    public private(set) var locks = [UUID: LockCache]() {
        
        didSet { writeCache() }
    }
    
    public private(set) var peripherals = [UUID: LockPeripheral]()
    
    /// Key identifier for the specified
    public subscript (lock identifier: UUID) -> LockCache? {
        
        get { return locks[identifier] }
        
        set { locks[identifier] = newValue }
    }
    
    public subscript (secret identifier: UUID) -> KeyData? {
        
        get {
            
            guard let data = try! keychain.getData(identifier.rawValue),
                let key = KeyData(data: data)
                else { return nil }
            
            return key
        }
        
        set {
            
            guard let data = newValue?.data
                else { try! keychain.remove(identifier.rawValue); return }
            
            try! keychain.set(data, key: identifier.rawValue)
        }
    }
    
    private func loadCache() {
        
        locks = defaults.get(for: storageKey) ?? [:]
    }
    
    private func writeCache() {
        
        defaults.set(locks, for: storageKey)
    }
}

public extension Store {
    
    func scan(duration: TimeInterval) throws {
        
        self.peripherals.removeAll()
        
        var peripherals = Set<LockManager.Peripheral>()
        
        try LockManager.shared.scan(duration: duration, filterDuplicates: false) { peripherals.insert($0) }
        
        for peripheral in peripherals {
            
            do {
                
                // read lock info, status and identifier
                let information = try LockManager.shared.readInformation(for: peripheral)
                
                // store peripheral cache
                self.peripherals[information.identifier] = LockPeripheral(peripheral: peripheral, information: information)
                
            } catch { log("Error: \(error)") }
        }
    }
    
    /// Setup a lock.
    func setup(_ peripheral: LockManager.Peripheral, sharedSecret: KeyData, name: String) throws {
        
        let request = SetupRequest()
        
        try LockManager.shared.setup(peripheral: peripheral,
                                     with: request,
                                     sharedSecret: sharedSecret)
        
        let newKey = Key(identifier: request.identifier,
                         name: "",
                         permission: .owner)
        
        let lockCache = LockCache(key: newKey, name: name)
        
        
    }
}

/// Lock Cache
public struct LockCache: Codable {
    
    /// Stored key for lock.
    ///
    /// Can only have one key per lock.
    public let key: Key
    
    /// User-friendly lock name
    public let name: String
}

/// Lock Peripheral
public struct LockPeripheral {
    
    public let peripheral: LockManager.Peripheral
    
    public var information: InformationCharacteristic
}
