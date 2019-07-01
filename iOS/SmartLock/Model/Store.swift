//
//  Store.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import Bluetooth
import CoreLock
import GATT

#if os(iOS)
import KeychainAccess
#endif

public final class Store {
    
    public static let shared = Store()
    
    private init() {
        
        loadCache()
    }
    
    public let scanning = Observable(false)
    
    public let locks = Observable([UUID: LockCache]())
    
    private let defaults = Defaults.shared
    
    private let keychain = Keychain()
    
    private let storageKey = DefaultsKey<[UUID: LockCache]>("locks")
    
    // BLE cache
    public private(set) var peripherals = Observable([NativeCentral.Peripheral: LockPeripheral<NativeCentral>]())
    
    public private(set) var lockInformation = Observable([NativeCentral.Peripheral: LockInformationCharacteristic]())
    
    /// Key identifier for the specified
    public subscript (lock identifier: UUID) -> LockCache? {
        
        get { return locks.value[identifier] }
        set {
            locks.value[identifier] = newValue
            writeCache()
        }
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
    
    public subscript (peripheral identifier: UUID) -> NativeCentral.Peripheral? {
        
        return lockInformation.value.first(where: { $0.value.identifier == identifier })?.key
    }
    
    @discardableResult
    public func remove(_ lock: UUID) -> Bool {
        
        guard let lockCache = self[lock: lock]
            else { return false }
        
        self[lock: lock] = nil
        self[key: lockCache.key.identifier] = nil
        
        return true
    }
    
    private func loadCache() {
        
        locks.value = defaults.get(for: storageKey) ?? [:]
    }
    
    private func writeCache() {
        
        defaults.set(locks.value, for: storageKey)
    }
}

public extension Store {
    
    func scan(duration: TimeInterval) throws {
        
        self.peripherals.value.removeAll()
        
        try LockManager.shared.scan(duration: duration, filterDuplicates: false) { [unowned self] in
            self.peripherals.value[$0.scanData.peripheral] = $0
        }
    }
    
    /// Setup a lock.
    func setup(_ lock: LockPeripheral<NativeCentral>,
               sharedSecret: KeyData,
               name: String) throws {
        
        let setupRequest = SetupRequest()
        
        let information = try LockManager.shared.setup(setupRequest,
                                                       for: lock.scanData.peripheral,
                                                       sharedSecret: sharedSecret)
        
        let ownerKey = Key(setup: setupRequest)
        
        let lockCache = LockCache(
            key: ownerKey,
            name: name,
            information: .init(characteristic: information)
        )
        
        // store key
        self[lock: information.identifier] = lockCache
        self[key: ownerKey.identifier] = setupRequest.secret
        
        // update lock information
        self.lockInformation.value[lock.scanData.peripheral] = information
    }
    
    func readInformation(_ lock: LockPeripheral<NativeCentral>) throws {
        
        let information = try LockManager.shared.readInformation(for: lock.scanData.peripheral)
        
        // update lock information cache
        self.lockInformation.value[lock.scanData.peripheral] = information
        self[lock: information.identifier]?.information = LockCache.Information(characteristic: information)
    }
}

/// Lock Cache
public struct LockCache: Codable, Equatable {
    
    /// Stored key for lock.
    ///
    /// Can only have one key per lock.
    public let key: Key
    
    /// User-friendly lock name
    public var name: String
    
    /// Lock information.
    public var information: Information
}

public extension LockCache {
    
    struct Information: Codable, Equatable {
        
        /// Firmware build number
        public var buildVersion: LockBuildVersion
        
        /// Firmware version
        public var version: LockVersion
        
        /// Device state
        public var status: LockStatus
        
        /// Supported lock actions
        public var unlockActions: Set<UnlockAction>
    }
}

internal extension LockCache.Information {
    
    init(characteristic: LockInformationCharacteristic) {
        
        self.buildVersion = characteristic.buildVersion
        self.version = characteristic.version
        self.status = characteristic.status
        self.unlockActions = Set(characteristic.unlockActions)
    }
}
