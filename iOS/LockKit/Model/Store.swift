//
//  Store.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation
import Bluetooth
import CoreLock
import GATT
import DarwinGATT
import KeychainAccess

public final class Store {
    
    public static let shared = Store()
    
    private init() {
        
        beaconController.foundLock = { [unowned self] (lock, beacon) in
            self.lockBeaconFound(lock: lock, beacon: beacon)
        }
        locks.observe { [unowned self] _ in self.lockCacheChanged() }
        loadCache()
    }
    
    public let scanning = Observable(false)
    
    public let locks = Observable([UUID: LockCache]())
    
    private let defaults: Defaults = Defaults(userDefaults: UserDefaults(suiteName: .lock)!)
    
    private let keychain = Keychain(service: .lock, accessGroup: .lock)
    
    private let storageKey = DefaultsKey<[UUID: LockCache]>("locks")
    
    public let lockManager: LockManager = .shared
    
    public let beaconController: BeaconController = .shared
    
    public let spotlight: SpotlightController = .shared
    
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
            
            do {
                guard let data = newValue?.data
                    else { try keychain.remove(identifier.rawValue); return }
                try keychain.set(data, key: identifier.rawValue)
            } catch {
                dump(error)
                fatalError("Unable store value in keychain: \(error)")
            }
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
    
    // Forceably load cache.
    public func loadCache() {
        
        locks.value = defaults.get(for: storageKey) ?? [:]
    }
    
    private func writeCache() {
        
        defaults.set(locks.value, for: storageKey)
    }
    
    private func lockCacheChanged() {
        
        monitorBeacons()
        updateSpotlight()
    }
    
    private func monitorBeacons() {
        
        // remove old beacons
        for lock in self.beaconController.locks.keys {
            if self.locks.value.keys.contains(lock) == false {
                self.beaconController.stopMonitoring(lock: lock)
            }
        }
        
        // add new beacons
        for lock in self.locks.value.keys {
            if self.beaconController.locks.keys.contains(lock) == false {
                self.beaconController.monitor(lock: lock)
            }
        }
    }
    
    private func updateSpotlight() {
        
        spotlight.update(locks: locks.value)
    }
    
    private func lockBeaconFound(lock: UUID, beacon: CLBeacon) {
        
        async {
            do {
                guard let _ = try Store.shared.device(for: lock, scanDuration: 1.0) else {
                    log("⚠️ Could not find lock \(lock) for beacon \(beacon)")
                    self.beaconController.scanBeacon(for: lock)
                    return
                }
            } catch {
                log("⚠️ Could not scan: \(error)")
            }
        }
    }
}

// MARK: - Lock Bluetooth Operations

public extension Store {
    
    func device(for identifier: UUID,
                scanDuration: TimeInterval) throws -> LockPeripheral<NativeCentral>? {
        
        assert(Thread.isMainThread == false)
        
        if let lock = device(for: identifier) {
            return lock
        } else {
            try self.scan(duration: scanDuration)
            for peripheral in peripherals.value.values {
                do { try self.readInformation(peripheral) }
                catch { log("⚠️ Could not read information : \(error)"); continue } // ignore
                if let foundDevice = device(for: identifier) {
                    return foundDevice
                }
            }
            return nil
        }
    }
    
    func device(for identifier: UUID) -> LockPeripheral<NativeCentral>? {
        
        guard let peripheral = self[peripheral: identifier],
            let lock = self.peripherals.value[peripheral]
            else { return nil }
        
        return lock
    }
    
    func scan(duration: TimeInterval) throws {
        
        assert(Thread.isMainThread == false)
        
        self.peripherals.value.removeAll()
        
        try lockManager.scanLocks(duration: duration, filterDuplicates: true) { [unowned self] in
            self.peripherals.value[$0.scanData.peripheral] = $0
        }
    }
    
    /// Setup a lock.
    func setup(_ lock: LockPeripheral<NativeCentral>,
               sharedSecret: KeyData,
               name: String) throws {
        
        assert(Thread.isMainThread == false)
        
        let setupRequest = SetupRequest()
        
        let information = try lockManager.setup(setupRequest,
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
        
        assert(Thread.isMainThread == false)
        
        let information = try lockManager.readInformation(for: lock.scanData.peripheral)
        
        // update lock information cache
        self.lockInformation.value[lock.scanData.peripheral] = information
        self[lock: information.identifier]?.information = LockCache.Information(characteristic: information)
    }
    
    @discardableResult
    func unlock(_ lock: LockPeripheral<NativeCentral>, action: UnlockAction = .default) throws -> Bool {
        
        // get lock key
        guard let information = self.lockInformation.value[lock.scanData.peripheral],
            let lockCache = self[lock: information.identifier],
            let keyData = self[key: lockCache.key.identifier]
            else { return false }
        
        let key = KeyCredentials(
            identifier: lockCache.key.identifier,
            secret: keyData
        )
        
        try lockManager.unlock(action,
                               for: lock.scanData.peripheral,
                               with: key)
        
        return true
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
