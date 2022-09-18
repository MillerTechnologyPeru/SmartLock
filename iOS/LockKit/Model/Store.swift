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

public final class Store: ObservableObject {
    
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
            Task {
                switch beacon.state {
                case .inside:
                    await self.beaconFound(beacon.uuid)
                case .outside:
                    await self.beaconExited(beacon.uuid)
                }
            }
        }
        
        // observe external cloud changes
        cloud.didChange = { [unowned self] in self.cloudDidChangeExternally() }
        #endif
        
        // observe local cache changes
        locksObserver = $locks
            .sink(receiveValue: { [weak self] _ in self?.lockCacheChanged() })
        
        // read from filesystem
        loadCache()
    }
    
    @Published
    public var isScanning = false
    
    @Published
    public var locks = [UUID: LockCache]()
    
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
            if locks != newValue.locks {
                locks = newValue.locks // update locks
            }
        }
    }
    
    public lazy var central: NativeCentral =  DarwinCentral(options: .init(showPowerAlert: false, restoreIdentifier: nil))
    
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
    
    //public lazy var netServiceClient: LockNetServiceClient = .shared
    #endif
    
    // BLE cache
    
    @Published
    public var peripherals = [NativeCentral.Peripheral: ScanData<NativeCentral.Peripheral, NativeCentral.Advertisement>]()
    
    @Published
    public var lockInformation = [NativeCentral.Peripheral: LockInformation]()
    
    private var locksObserver: Combine.AnyCancellable?
    
    // MARK: - Subscript
    
    /// Cached information for the specified lock.
    public subscript (lock id: UUID) -> LockCache? {
        
        get { return locks[id] }
        set {
            locks[id] = newValue // update observers
            applicationData.locks = locks // write file
        }
    }
    
    /// Private Key for the specified lock.
    public subscript (key id: UUID) -> KeyData? {
        
        get {
            
            do {
                guard let data = try keychain.getData(id.uuidString)
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
            let key = id.uuidString
            do {
                guard let data = newValue?.data else {
                    try keychain.remove(key)
                    return
                }
                if try keychain.contains(key) {
                    try keychain.remove(key)
                }
                try keychain.set(data, key: key)
            }
            catch {
                #if DEBUG
                print(error)
                #endif
                assertionFailure("Unable store value in keychain: \(error)")
            }
        }
    }
    
    /// The Bluetooth LE peripheral for the speciifed lock.
    public subscript (peripheral id: UUID) -> NativeCentral.Peripheral? {
        return lockInformation.first(where: { $0.value.id == id })?.key
    }
    
    /// Remove the specified lock from the cache and keychain.
    @discardableResult
    public func remove(_ lock: UUID) -> Bool {
        
        guard let lockCache = self[lock: lock]
            else { return false }
        
        self[lock: lock] = nil
        self[key: lockCache.key.id] = nil
        
        return true
    }
    
    /// Get credentials from Keychain to authorize requests.
    public func credentials(for lock: UUID) -> KeyCredentials? {
        guard let cache = self[lock: lock],
            let keyData = self[key: cache.key.id]
            else { return nil }
        return .init(id: cache.key.id, secret: keyData)
    }
    
    /// Forceably load cache.
    public func loadCache() {
        
        // read file
        let applicationData = self.applicationData
        // set value
        if locks != applicationData.locks {
            locks = applicationData.locks
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
        
        let locks = self.locks
        backgroundContext.commit {
            try $0.insert(locks)
        }
    }
    
    #if os(iOS)
    private func monitorBeacons() {
        
        // always monitor lock notification iBeacon
        let beacons = Set(self.locks.keys) + [.lockNotificationBeacon]
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
        spotlight.reindexAll(locks: locks)
    }
    
    private func updateCloud() {
        /*
        DispatchQueue.cloud.async { [weak self] in
            guard let self = self else { return }
            do {
                guard try self.cloud.accountStatus() == .available else { return }
                try self.syncCloud()
            }
            catch { log("⚠️ Unable to sync iCloud: \(error.localizedDescription)") }
        }*/
    }
    
    @MainActor
    private func beaconFound(_ beacon: UUID) async {
        
        // Can't do anything because we don't have Bluetooth
        guard await central.state == .poweredOn
            else { return }
        
        if let _ = Store.shared[lock: beacon] {
            do {
                guard let _ = try await self.device(for: beacon, scanDuration: 1.0) else {
                    log("⚠️ Could not find lock \(beacon) for beacon \(beacon)")
                    self.beaconController.scanBeacon(for: beacon)
                    return
                }
                log("📶 Found lock \(beacon)")
            } catch {
                log("⚠️ Could not scan: \(error.localizedDescription)")
            }
        } else if beacon == .lockNotificationBeacon { // Entered region event
            log("📶 Lock notification")
            guard preferences.monitorBluetoothNotifications
                else { return } // ignore notification
            typealias FetchRequest = LockEvent.FetchRequest
            typealias Predicate = LockEvent.Predicate
            let context = Store.shared.backgroundContext
            
            // scan for all locks
            let locks = Store.shared.locks.keys
            // scan if none is visible
            if locks.compactMap({ self.device(for: $0) }).isEmpty {
                do { try await Store.shared.scan(duration: 1.0) }
                catch { log("⚠️ Could not scan for locks: \(error.localizedDescription)") }
            }
            let visibleLocks = locks.filter { self.device(for: $0) != nil }
            // queue fetching events
            try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
            defer { self.beaconController.scanBeacons() } // refresh beacons
            for lock in visibleLocks {
                do {
                    guard let device = try await self.device(for: lock, scanDuration: 1.0)
                        else { continue }
                    let lastEventDate = try context.performErrorBlockAndWait {
                        try context.find(id: lock, type: LockManagedObject.self)
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
                    try await self.listEvents(device, fetchRequest: fetchRequest, notification: { _,_ in })
                } catch {
                    log("⚠️ Could not fetch latest data for lock \(lock): \(error.localizedDescription)")
                    continue
                }
            }
        }
    }
    
    @MainActor
    private func beaconExited(_ beacon: UUID) async {
        
        guard let _ = Store.shared[lock: beacon]
            else { return }
        
        do {
            try await self.scan(duration: 1.0)
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
    #endif
}

// MARK: - Lock Bluetooth Operations

@MainActor
public extension Store {
    
    func device(for id: UUID,
                scanDuration: TimeInterval) async throws -> NativeCentral.Peripheral? {
                
        if let lock = device(for: id) {
            return lock
        } else {
            try await self.scan(duration: scanDuration)
            for peripheral in peripherals.keys {
                // skip known locks that are not the targeted device
                if let information = lockInformation[peripheral] {
                    guard information.id == id else { continue }
                }
                // request information
                do {
                    try await self.readInformation(peripheral)
                } catch {
                    log("⚠️ Could not read information: \(error.localizedDescription)")
                    continue // ignore
                }
                if let foundDevice = device(for: id) {
                    return foundDevice
                }
            }
            return device(for: id)
        }
    }
    
    func device(for id: UUID) -> NativeCentral.Peripheral? {
        self[peripheral: id]
    }
    
    func key(for lock: NativeCentral.Peripheral) -> KeyCredentials? {
        
        guard let information = self.lockInformation[lock],
            let lockCache = self[lock: information.id],
            let keyData = self[key: lockCache.key.id]
            else { return nil }
        
        let key = KeyCredentials(
            id: lockCache.key.id,
            secret: keyData
        )
        
        return key
    }
    
    func scan(duration: TimeInterval? = nil) async throws {
        
        let duration = duration ?? preferences.scanDuration
        let filterDuplicates = preferences.filterDuplicates
        self.peripherals.removeAll()
        let stream = central.scan(with: [LockService.uuid])
        for try await scanData in stream {
            guard let serviceUUIDs = scanData.advertisementData.serviceUUIDs,
                serviceUUIDs.contains(LockService.uuid)
                else { continue }
            // cache found device
            self.peripherals[scanData.peripheral] = scanData
        }
        //try lockManager.scanLocks(duration: duration, filterDuplicates: filterDuplicates) { [unowned self] in
        //    self.peripherals.value[$0.scanData.peripheral] = $0
        //}
    }
    
    /// Setup a lock.
    func setup(
        _ lock: NativeCentral.Peripheral,
        sharedSecret: KeyData,
        name: String
    ) async throws {
        
        let setupRequest = SetupRequest()
        let information = try await central.setup(
            setupRequest,
            using: sharedSecret,
            for: lock
        )
        
        let ownerKey = Key(setup: setupRequest)
        let lockCache = LockCache(
            key: ownerKey,
            name: name,
            information: .init(information)
        )
        
        // store key
        self[lock: information.id] = lockCache
        self[key: ownerKey.id] = setupRequest.secret
        
        // update lock information
        self.lockInformation[lock] = information
    }
    
    func readInformation(_ lock: NativeCentral.Peripheral) async throws {
        
        assert(Thread.isMainThread == false)
        
        let information = try await central.readInformation(
            for: lock
        )
        
        // update lock information cache
        self.lockInformation[lock] = information
        self[lock: information.id]?.information = LockCache.Information(information)
    }
    
    @discardableResult
    func unlock(_ lock: NativeCentral.Peripheral, action: UnlockAction = .default) async throws -> Bool {
        
        // get lock key
        guard let key = self.key(for: lock)
            else { return false }
        
        try await central.unlock(
            action,
            using: key,
            for: lock
        )
        
        return true
    }
    
    @discardableResult
    func listKeys(
        _ lock: NativeCentral.Peripheral,
        notification updateBlock: ((KeysList, Bool) -> ()) = { _,_ in }
    ) async throws -> Bool {
        
        // get lock key
        guard let information = self.lockInformation[lock],
            let lockCache = self[lock: information.id],
            let keyData = self[key: lockCache.key.id]
            else { return false }
        
        let key = KeyCredentials(
            id: lockCache.key.id,
            secret: keyData
        )
            
        let context = backgroundContext
        
        // BLE request
        try await central.connection(for: lock) {
            let stream = try await $0.listKeys(using: key, log: { log("📲 Central: " + $0) })
            var list = KeysList()
            for try await notification in stream {
                list.append(notification.key)
                // call completion block
                updateBlock(list, notification.isLast)
                await context.commit { (context) in
                    try context.insert(notification.key, for: information.id)
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
    func listEvents(
        _ lock: NativeCentral.Peripheral,
        fetchRequest: LockEvent.FetchRequest? = nil,
        notification updateBlock: @escaping ((EventsList, Bool) -> ()) = { _,_ in }
    ) async throws -> Bool {
        
        // get lock key
        guard let information = self.lockInformation[lock],
            let lockCache = self[lock: information.id],
            let keyData = self[key: lockCache.key.id]
            else { return false }
        
        let key = KeyCredentials(
            id: lockCache.key.id,
            secret: keyData
        )
        
        let lockIdentifier = information.id
        let context = backgroundContext
        
        // BLE request
        let log = central.log
        try await central.connection(for: lock) {
            let stream = try await $0.listEvents(fetchRequest: fetchRequest, using: key, log: log)
            var events = [LockEvent]()
            for try await notification in stream {
                if let event = notification.event {
                    events.append(event)
                    log?("Recieved event \(event.id)")
                    await context.commit { (context) in
                        try context.insert(event, for: information.id)
                    }
                }
                // call completion block
                updateBlock(events, notification.isLast)
                
            }
        }
        
        /*
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
        */
        return true
    }
}
/*
// MARK: - Bonjour Requests

#if os(iOS)

public extension Store {
    
    @discardableResult
    func listEvents(_ lock: LockNetService,
                    fetchRequest: LockEvent.FetchRequest? = nil) throws -> Bool {
        
        // get lock key
        guard let lockCache = self[lock: lock.id],
            let keyData = self[key: lockCache.key.id]
            else { return false }
        
        let key = KeyCredentials(
            id: lockCache.key.id,
            secret: keyData
        )
        
        let events = try netServiceClient.listEvents(
            fetchRequest: fetchRequest,
            for: lock,
            with: key,
            timeout: 30
        )
        
        backgroundContext.commit { (context) in
            try context.insert(events, for: lock.id)
        }
        
        #if os(iOS)
        if preferences.isCloudBackupEnabled {
            DispatchQueue.cloud.async { [weak self] in
                // upload to iCloud
                do {
                    for event in events {
                        let value = LockEvent.Cloud(event: event, for: lock.id)
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

#endif
*/
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
