//
//  Store.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import Bluetooth
import CoreLock
import GATT
import KeychainAccess

public final class Store {
    
    // MARK: - Initialization
    
    public static let shared = Store()
    
    private init() {
        locks = defaults.get(for: locksStorageKey) ?? [:]
        scanDuration = defaults.get(for: scanDurationStorageKey) ?? 10.0
    }
    
    // MARK: - Methods
    
    public let didChange = PassthroughSubject<Store, Never>()
    
    private let defaults = Defaults.shared
    private let keychain = Keychain()
    
    // Stored keys
    private let locksStorageKey = DefaultsKey<[UUID: LockCache]>("locks")
    private var locks = [UUID: LockCache]() {
        didSet {
            didChange.send(self)
            defaults.set(locks, for: locksStorageKey)
        }
    }
    
    private let scanDurationStorageKey = DefaultsKey<TimeInterval>("scanDuration")
    public var scanDuration: TimeInterval = 10.0 {
        didSet {
            didChange.send(self)
            defaults.set(scanDuration, for: scanDurationStorageKey)
        }
    }
    
    // BLE cache
    public private(set) var isScanning = false {
        didSet { didChange.send(self) }
    }
    public private(set) var peripherals = [Peripheral: LockPeripheral]() {
        didSet { didChange.send(self) }
    }
    public private(set) var lockInformation = [Peripheral: InformationCharacteristic]() {
        didSet { didChange.send(self) }
    }
    
    // MARK: - Subscript
    
    /// Key identifier for the specified
    public subscript (lock identifier: UUID) -> LockCache? {
        
        get { return locks[identifier] }
        set { locks[identifier] = newValue }
    }
    
    public subscript (key identifier: UUID) -> KeyData? {
        
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
}

// MARK: - Device Methods

public extension Store {
    
    func scan(duration: TimeInterval) throws {
        
        self.isScanning = true
        defer { self.isScanning = false }
        
        self.peripherals.removeAll()
        
        try LockManager.shared.scan(duration: duration, filterDuplicates: false) { [unowned self] in
            self.peripherals[$0.scanData.peripheral] = $0
        }
    }
    
    /// Setup a lock.
    func setup(_ lock: LockPeripheral,
               sharedSecret: KeyData,
               name: String) throws {
        
        let setupRequest = SetupRequest()
        
        let information = try LockManager.shared.setup(peripheral: lock.scanData.peripheral,
                                                       with: setupRequest,
                                                       sharedSecret: sharedSecret)
        
        let ownerKey = Key(setup: setupRequest)
        
        let lockCache = LockCache(key: ownerKey, name: name)
        
        // store key
        self[lock: information.identifier] = lockCache
        self[key: ownerKey.identifier] = setupRequest.secret
        
        // update lock information
        self.lockInformation[lock.scanData.peripheral] = information
    }
    
    func readInformation(_ lock: LockPeripheral) throws {
        
        let information = try LockManager.shared.readInformation(for: lock.scanData.peripheral)
        
        // update lock information
        self.lockInformation[lock.scanData.peripheral] = information
    }
}

// MARK: - Supporting Types

/// Lock Cache
public struct LockCache: Equatable, Codable {
    
    /// Stored key for lock.
    ///
    /// Can only have one key per lock.
    public let key: Key
    
    /// User-friendly lock name
    public let name: String
}
