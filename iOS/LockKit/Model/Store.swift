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
import Combine
import OpenCombine

public final class Store {
    
    public static let shared = Store()
    
    private init() {
        
        // clear keychain on newly installed app.
        if preferences.isAppInstalled == false {
            preferences.isAppInstalled = true
            do { try keychain.removeAll() }
            catch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    #if DEBUG
                    dump(error)
                    #endif
                    log("⚠️ Unable to clear keychain: \(error.localizedDescription)")
                    assertionFailure("Unable to clear keychain")
                }
            }
        }
        
        #if os(iOS)
        // observe iBeacons
        beaconController.foundLock = { [unowned self] (lock, beacon) in
            self.lockBeaconFound(lock: lock, beacon: beacon)
        }
        beaconController.lostLock = { [unowned self] (lock) in
            self.lockBeaconExited(lock: lock)
        }
        #endif
        
        // observe local cache changes
        locksObserver = locks.sink(receiveValue: { [unowned self] _ in
            self.lockCacheChanged()
        })
        
        #if os(iOS)
        // observe external cloud changes
        cloud.didChange = { [unowned self] in self.cloudDidChangeExternally() }
        #endif
        
        // read from filesystem
        loadCache()
    }
    
    @available(iOS 13.0, watchOSApplicationExtension 6.0, *)
    public lazy var objectWillChange = ObservableObjectPublisher()
    
    public let isScanning = OpenCombine.CurrentValueSubject<Bool, Never>(false)
    
    public let locks = OpenCombine.CurrentValueSubject<[UUID: LockCache], Never>([UUID: LockCache]())
    
    public lazy var preferences = Preferences(suiteName: .lock)!
    
    internal lazy var keychain = Keychain(service: .lock, accessGroup: .lock)
    
    public lazy var fileManager: FileManager.Lock = .shared
    
    public var applicationData: ApplicationData {
        get {
            if let applicationData = fileManager.applicationData {
                return applicationData
            } else {
                let applicationData = ApplicationData()
                fileManager.applicationData = applicationData
                return applicationData
            }
        }
        set {
            fileManager.applicationData = newValue
            locks.value = newValue.locks // update locks
        }
    }
    
    public lazy var lockManager: LockManager = .shared
    
    #if os(iOS)
    public lazy var cloud: CloudStore = .shared
    
    public lazy var beaconController: BeaconController = .shared
    
    public lazy var spotlight: SpotlightController = .shared
    #endif
    
    // BLE cache
    public let peripherals = OpenCombine.CurrentValueSubject<[NativeCentral.Peripheral: LockPeripheral<NativeCentral>], Never>([NativeCentral.Peripheral: LockPeripheral<NativeCentral>]())
    
    public let lockInformation = OpenCombine.CurrentValueSubject<[NativeCentral.Peripheral: LockInformationCharacteristic], Never>([NativeCentral.Peripheral: LockInformationCharacteristic]())
    
    private var locksObserver: AnyCancellable?
    
    // MARK: - Subscript
    
    /// Cached information for the specified lock.
    public subscript (lock identifier: UUID) -> LockCache? {
        
        get { return locks.value[identifier] }
        set {
            locks.value[identifier] = newValue
            writeCache()
        }
    }
    
    /// Private Key for the specified lock.
    public subscript (key identifier: UUID) -> KeyData? {
        
        get {
            
            do {
                guard let data = try keychain.getData(identifier.uuidString)
                    else { return nil }
                guard let key = KeyData(data: data)
                    else { assertionFailure("Invalid key data"); return nil }
                return key
            } catch {
                #if DEBUG
                dump(error)
                #endif
                assertionFailure("Unable retrieve value from keychain: \(error)")
                return nil
            }
        }
        
        set {
                        
            do {
                guard let data = newValue?.data else {
                    try keychain.remove(identifier.uuidString)
                    return
                }
                try keychain.set(data, key: identifier.uuidString)
            } catch {
                #if DEBUG
                dump(error)
                #endif
                assertionFailure("Unable store value in keychain: \(error)")
            }
        }
    }
    
    /// The Bluetooth LE peripheral for the speciifed lock.
    public subscript (peripheral identifier: UUID) -> NativeCentral.Peripheral? {
        
        return lockInformation.value.first(where: { $0.value.identifier == identifier })?.key
    }
    
    /// Remove the specified lock from the cache and keychain.
    @discardableResult
    public func remove(_ lock: UUID) -> Bool {
        
        guard let lockCache = self[lock: lock]
            else { return false }
        
        self[lock: lock] = nil
        self[key: lockCache.key.identifier] = nil
        
        return true
    }
    
    /// Forceably load cache.
    public func loadCache() {
        
        // read file
        let applicationData = self.applicationData
        // set value
        locks.value = applicationData.locks
    }
    
    /// Write to lock cache.
    private func writeCache() {
        
        // write file
        applicationData.locks = locks.value
    }
    
    private func lockCacheChanged() {
        
        #if os(iOS)
        monitorBeacons()
        updateSpotlight()
        updateCloud()
        #endif
    }
    
    #if os(iOS)
    
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
    
    private func updateCloud() {
        
        DispatchQueue.cloud.async { [weak self] in
            do { try self?.syncCloud() }
            catch { log("⚠️ Unable to sync iCloud: \(error)") }
        }
    }
    
    private func lockBeaconFound(lock: UUID, beacon: CLBeacon) {
        
        async { [weak self] in
            guard let self = self else { return }
            do {
                guard let _ = try self.device(for: lock, scanDuration: 1.0) else {
                    log("⚠️ Could not find lock \(lock) for beacon \(beacon)")
                    self.beaconController.scanBeacon(for: lock)
                    return
                }
            } catch {
                log("⚠️ Could not scan: \(error)")
            }
        }
    }
    
    private func lockBeaconExited(lock: UUID) {
        
        async { [weak self] in
            guard let self = self else { return }
            do {
                try self.scan(duration: 1.0)
                if self.device(for: lock) == nil {
                    log("Lock \(lock) no longer in range")
                } else {
                    // lock is in range, refresh beacons
                    self.beaconController.scanBeacon(for: lock)
                }
            } catch {
                log("⚠️ Could not scan: \(error)")
            }
        }
    }
    
    #endif
}

// MARK: - ObservableObject

extension Store: Combine.ObservableObject { }

// MARK: - Lock Bluetooth Operations

public extension Store {
    
    func device(for identifier: UUID,
                scanDuration: TimeInterval? = nil) throws -> LockPeripheral<NativeCentral>? {
        
        assert(Thread.isMainThread == false)
        
        let scanDuration = scanDuration ?? preferences.scanDuration
        if let lock = device(for: identifier) {
            return lock
        } else {
            try self.scan(duration: scanDuration)
            for peripheral in peripherals.value.values {
                // skip known locks that are not the targeted device
                if let information = lockInformation.value[peripheral.scanData.peripheral] {
                    guard information.identifier == identifier else { continue }
                }
                // request information
                do { try self.readInformation(peripheral) }
                catch { log("⚠️ Could not read information: \(error)"); continue } // ignore
                if let foundDevice = device(for: identifier) {
                    return foundDevice
                }
            }
            return device(for: identifier)
        }
    }
    
    func device(for identifier: UUID) -> LockPeripheral<NativeCentral>? {
        
        guard let peripheral = self[peripheral: identifier],
            let lock = self.peripherals.value[peripheral]
            else { return nil }
        
        return lock
    }
    
    func scan(duration: TimeInterval? = nil) throws {
        
        let duration = preferences.scanDuration
        let filterDuplicates = preferences.filterDuplicates
        assert(Thread.isMainThread == false)
        self.peripherals.value.removeAll()
        try lockManager.scanLocks(duration: duration, filterDuplicates: filterDuplicates) { [unowned self] in
            self.peripherals.value[$0.scanData.peripheral] = $0
        }
    }
    
    /// Setup a lock.
    func setup(_ lock: LockPeripheral<NativeCentral>,
               sharedSecret: KeyData,
               name: String) throws {
        
        assert(Thread.isMainThread == false)
        let setupRequest = SetupRequest()
        let information = try lockManager.setup(
            setupRequest,
            for: lock.scanData.peripheral,
            sharedSecret: sharedSecret,
            timeout: preferences.bluetoothTimeout
        )
        
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
        
        let information = try lockManager.readInformation(
            for: lock.scanData.peripheral,
            timeout: preferences.bluetoothTimeout
        )
        
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
                               with: key,
                               timeout: preferences.bluetoothTimeout)
        return true
    }
}
