//
//  Store.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
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
                log("⚠️ Unable to clear keychain: \(error.localizedDescription)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    #if DEBUG
                    print(error)
                    #endif
                    assertionFailure("Unable to clear keychain")
                }
            }
        }
        
        // load CoreData
        let semaphore = DispatchSemaphore(value: 0)
        persistentContainer.loadPersistentStores { (store, error) in
            semaphore.signal()
            if let error = error {
                log("⚠️ Unable to load persistent store: \(error.localizedDescription)")
                #if DEBUG
                print(error)
                #endif
                if let url = store.url {
                    do { try FileManager.default.removeItem(at: url) }
                    catch { print(error) }
                }
                assertionFailure("Unable to load persistent store")
                return
            }
            #if DEBUG
            print("🗄 Loaded persistent store")
            print(store)
            #endif
        }
        let didTimeout = semaphore.wait(timeout: .now() + 5.0) == .timedOut
        assert(didTimeout == false)
        
        #if os(iOS)
        // observe iBeacons
        beaconController.beaconChanged = { [unowned self] (beacon) in
            switch beacon.state {
            case .inside:
                self.beaconFound(beacon.uuid)
            case .outside:
                self.beaconExited(beacon.uuid)
            }
        }
        
        // observe external cloud changes
        cloud.didChange = { [unowned self] in self.cloudDidChangeExternally() }
        #endif
        
        // observe local cache changes
        locksObserver = locks
            .sink(receiveValue: { [weak self] _ in self?.lockCacheChanged() })
        
        // read from filesystem
        loadCache()
    }
    
    @available(iOS 13.0, watchOSApplicationExtension 6.0, *)
    public lazy var objectWillChange = Combine.ObservableObjectPublisher()
    
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
            if locks.value != newValue.locks {
                locks.value = newValue.locks // update locks
            }
        }
    }
    
    public lazy var lockManager: LockManager = .shared
    
    internal lazy var persistentContainer: NSPersistentContainer = .lock
    
    public lazy var managedObjectContext: NSManagedObjectContext = {
        let context = self.persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.undoManager = nil
        return context
    }()
    
    internal lazy var backgroundContext: NSManagedObjectContext = {
        let context = self.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        context.undoManager = nil
        return context
    }()
    
    #if os(iOS)
    public lazy var cloud: CloudStore = .shared
    
    public lazy var beaconController: BeaconController = .shared
    
    public lazy var spotlight: SpotlightController = .shared
    
    public lazy var netServiceClient: LockNetServiceClient = .shared
    #endif
    
    // BLE cache
    public let peripherals = OpenCombine.CurrentValueSubject<[NativeCentral.Peripheral: LockPeripheral<NativeCentral>], Never>([NativeCentral.Peripheral: LockPeripheral<NativeCentral>]())
    
    public let lockInformation = OpenCombine.CurrentValueSubject<[NativeCentral.Peripheral: LockInformationCharacteristic], Never>([NativeCentral.Peripheral: LockInformationCharacteristic]())
    
    private var locksObserver: OpenCombine.AnyCancellable?
    
    // MARK: - Subscript
    
    /// Cached information for the specified lock.
    public subscript (lock identifier: UUID) -> LockCache? {
        
        get { return locks.value[identifier] }
        set {
            locks.value[identifier] = newValue // update observers
            applicationData.locks = locks.value // write file
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
                print(error)
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
                print(error)
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
        if locks.value != applicationData.locks {
            locks.value = applicationData.locks
        }
    }
    
    private func lockCacheChanged() {
        
        updateCoreData()
        
        #if !targetEnvironment(macCatalyst)
        if #available(iOS 12.0, watchOS 5.0, *) {
            setRelevantShortcuts()
        }
        #endif
        
        #if os(iOS)
        monitorBeacons()
        updateSpotlight()
        updateCloud()
        #endif
    }
    
    internal func updateCoreData() {
        
        let locks = self.locks.value
        backgroundContext.commit {
            try $0.insert(locks)
        }
    }
    
    #if os(iOS)
    
    private func monitorBeacons() {
        
        // always monitor lock notification iBeacon
        let beacons = Set(self.locks.value.keys) + [.lockNotificationBeacon]
        let oldBeacons = self.beaconController.beacons.keys
        
        // remove old beacons
        for beacon in oldBeacons {
            if beacons.contains(beacon) == false {
                self.beaconController.stopMonitoring(beacon)
            }
        }
        
        // add new beacons
        for beacon in beacons {
            if oldBeacons.contains(beacon) == false {
                self.beaconController.monitor(beacon)
            }
        }
    }
    
    private func updateSpotlight() {
        
        guard SpotlightController.isSupported else { return }
        spotlight.reindexAll(locks: locks.value)
    }
    
    private func updateCloud() {
        
        DispatchQueue.cloud.async { [weak self] in
            guard let self = self else { return }
            do {
                guard try self.cloud.accountStatus() == .available else { return }
                try self.syncCloud()
            }
            catch { log("⚠️ Unable to sync iCloud: \(error.localizedDescription)") }
        }
    }
    
    private func beaconFound(_ beacon: UUID) {
        
        // Can't do anything because we don't have Bluetooth
        guard lockManager.central.state == .poweredOn
            else { return }
        
        if let _ = Store.shared[lock: beacon] {
            DispatchQueue.bluetooth.async { [weak self] in
                guard let self = self else { return }
                do {
                    guard let _ = try self.device(for: beacon, scanDuration: 1.0) else {
                        log("⚠️ Could not find lock \(beacon) for beacon \(beacon)")
                        self.beaconController.scanBeacon(for: beacon)
                        return
                    }
                    log("📶 Found lock \(beacon)")
                } catch {
                    log("⚠️ Could not scan: \(error.localizedDescription)")
                }
            }
        } else if beacon == .lockNotificationBeacon { // Entered region event
            log("📶 Lock notification")
            guard preferences.monitorBluetoothNotifications
                else { return } // ignore notification
            typealias FetchRequest = ListEventsCharacteristic.FetchRequest
            typealias Predicate = ListEventsCharacteristic.Predicate
            let context = Store.shared.backgroundContext
            DispatchQueue.bluetooth.async {
                // scan for all locks
                let locks = Store.shared.locks.value.keys
                // scan if none is visible
                if locks.compactMap({ self.device(for: $0) }).isEmpty {
                    do { try Store.shared.scan(duration: 1.0) }
                    catch { log("⚠️ Could not scan for locks: \(error.localizedDescription)") }
                }
                let visibleLocks = locks.filter { self.device(for: $0) != nil }
                // queue fetching events
                DispatchQueue.bluetooth.asyncAfter(deadline: .now() + 3.0) {
                    defer { self.beaconController.scanBeacons() } // refresh beacons
                    for lock in visibleLocks {
                        do {
                            guard let device = try self.device(for: lock, scanDuration: 1.0)
                                else { continue }
                            let lastEventDate = try context.performErrorBlockAndWait {
                                try context.find(identifier: lock, type: LockManagedObject.self)
                                    .flatMap { try $0.lastEvent(in: context)?.date }
                            }
                            let fetchRequest = FetchRequest(
                                offset: 0,
                                limit: nil,
                                predicate: Predicate(
                                    keys: nil,
                                    start: lastEventDate,
                                    end: nil
                                )
                            )
                            try self.listEvents(device, fetchRequest: fetchRequest, notification: { _,_ in })
                        } catch {
                            log("⚠️ Could not fetch latest data for lock \(lock): \(error.localizedDescription)")
                            continue
                        }
                    }
                }
            }
        }
    }
    
    private func beaconExited(_ beacon: UUID) {
        
        guard let _ = Store.shared[lock: beacon]
            else { return }
        
        DispatchQueue.bluetooth.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.scan(duration: 1.0)
                if self.device(for: beacon) == nil {
                    log("Lock \(beacon) no longer in range")
                } else {
                    // lock is in range, refresh beacons
                    self.beaconController.scanBeacon(for: beacon)
                }
            } catch {
                log("⚠️ Could not scan: \(error.localizedDescription)")
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
                scanDuration: TimeInterval) throws -> LockPeripheral<NativeCentral>? {
        
        assert(Thread.isMainThread == false)
        
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
                do {
                    try self.readInformation(peripheral)
                } catch {
                    log("⚠️ Could not read information: \(error.localizedDescription)")
                    continue // ignore
                }
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
    
    func key(for lock: LockPeripheral<NativeCentral>) -> KeyCredentials? {
        
        guard let information = self.lockInformation.value[lock.scanData.peripheral],
            let lockCache = self[lock: information.identifier],
            let keyData = self[key: lockCache.key.identifier]
            else { return nil }
        
        let key = KeyCredentials(
            identifier: lockCache.key.identifier,
            secret: keyData
        )
        
        return key
    }
    
    func scan(duration: TimeInterval? = nil) throws {
        
        let duration = duration ?? preferences.scanDuration
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
        guard let key = self.key(for: lock)
            else { return false }
        
        try lockManager.unlock(action,
                               for: lock.scanData.peripheral,
                               with: key,
                               timeout: preferences.bluetoothTimeout)
        return true
    }
    
    @discardableResult
    func listKeys(_ lock: LockPeripheral<NativeCentral>,
                  notification: @escaping ((KeysList, Bool) -> ()) = { _,_ in }) throws -> Bool {
        
        // get lock key
        guard let information = self.lockInformation.value[lock.scanData.peripheral],
            let lockCache = self[lock: information.identifier],
            let keyData = self[key: lockCache.key.identifier]
            else { return false }
        
        let key = KeyCredentials(
            identifier: lockCache.key.identifier,
            secret: keyData
        )
        
        // BLE request
        try lockManager.listKeys(for: lock.scanData.peripheral, with: key, timeout: preferences.bluetoothTimeout) { [weak self] (list, isComplete) in
            // call completion block
            notification(list, isComplete)
            // store in CoreData
            guard list.keys.isEmpty == false else { return }
            self?.backgroundContext.commit { (context) in
                try list.keys.forEach {
                    try context.insert($0, for: information.identifier)
                }
                try list.newKeys.forEach {
                    try context.insert($0, for: information.identifier)
                }
            }
        }
        
        // upload keys to cloud
        #if os(iOS)
        updateCloud()
        #endif
        
        return true
    }
    
    @discardableResult
    func listEvents(_ lock: LockPeripheral<NativeCentral>,
                    fetchRequest: ListEventsCharacteristic.FetchRequest? = nil,
                    notification: @escaping ((EventsList, Bool) -> ()) = { _,_ in }) throws -> Bool {
        
        // get lock key
        guard let information = self.lockInformation.value[lock.scanData.peripheral],
            let lockCache = self[lock: information.identifier],
            let keyData = self[key: lockCache.key.identifier]
            else { return false }
        
        let key = KeyCredentials(
            identifier: lockCache.key.identifier,
            secret: keyData
        )
        
        let lockIdentifier = information.identifier
        
        // BLE request
        var events = [LockEvent]()
        try lockManager.listEvents(fetchRequest: fetchRequest, for: lock.scanData.peripheral, with: key, timeout: preferences.bluetoothTimeout) { [weak self] (list, isComplete) in
            // call completion block
            notification(list, isComplete)
            events = list
            // store in CoreData
            self?.backgroundContext.commit { (context) in
                try context.insert(list, for: information.identifier)
            }
        }
        
        #if os(iOS)
        if preferences.isCloudBackupEnabled {
            DispatchQueue.cloud.async { [weak self] in
                // upload to iCloud
                do {
                    for event in events {
                        let value = LockEvent.Cloud(event: event, for: lockIdentifier)
                        try self?.cloud.upload(value)
                    }
                } catch {
                    log("⚠️ Could not upload latest events to iCloud: \(error.localizedDescription)")
                }
            }
        }
        #endif
        
        return true
    }
}

// MARK: - CloudKit Operations

#if os(iOS)
public extension Store {
    
    func fetchCloudNewKeys(_ invitation: (URL, NewKey.Invitation) -> ()) throws {
        
        try cloud.fetchNewKeyShares {
            try $0.forEach {
                let url = try fileManager.save(invitation: $0)
                invitation(url, $0)
            }
        }
    }
}
#endif
