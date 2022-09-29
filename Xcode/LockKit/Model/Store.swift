//
//  Store.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import Foundation
import CoreData
import Combine
@_exported import Bluetooth
@_exported import GATT
@_exported import CoreLock
import DarwinGATT
import KeychainAccess
import Predicate

/// Lock Store object
@MainActor
public final class Store: ObservableObject {
    
    public static let shared = Store()
    
    // MARK: - Properties
    
    @Published
    public internal(set) var state: DarwinBluetoothState = .unknown
    
    @Published
    public internal(set) var isScanning = false
    
    @Published
    public internal(set) var peripherals = [NativePeripheral: ScanData<NativeCentral.Peripheral, NativeCentral.Advertisement>]()
    
    @Published
    public internal(set) var lockInformation = [NativePeripheral: LockInformation]()
    
    public lazy var central = NativeCentral.shared
    
    private var scanStream: AsyncCentralScan<NativeCentral>?
    
    public lazy var preferences = Preferences(suiteName: .lock)!
    
    internal lazy var keychain = Keychain(service: .lock, accessGroup: .lock)
    
    #if canImport(CoreSpotlight) && os(iOS) || os(macOS)
    public lazy var spotlight: SpotlightController = .shared
    #endif
    
    internal lazy var fileManager: FileManager.Lock = .shared
    
    public lazy var newKeyInvitations: NewKeyInvitationStore = .shared
    
    public lazy var persistentContainer: NSPersistentContainer = .lock
    
    public lazy var managedObjectContext: NSManagedObjectContext = {
        let context = self.persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.undoManager = nil
        return context
    }()
    
    public lazy var backgroundContext: NSManagedObjectContext = {
        let context = self.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        context.undoManager = nil
        return context
    }()
    
    public lazy var cloud: CloudStore = .shared
    
    // MARK: - Initialization
    
    private init() {
        central.log = { log("📲 Central: " + $0) }
        clearKeychainNewInstall()
        loadPersistentStore()
        observeBluetoothState()
        Task {
            //await lockCacheChanged()
            #if targetEnvironment(simulator)
            if await ((try? cloud.accountStatus()) ?? .couldNotDetermine) != .available {
                insertMockData()
            }
            #endif
        }
    }
}

// MARK: - Keychain

public extension Store {
    
    /// Clear keychain on newly installed app.
    private func clearKeychainNewInstall() {
        
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
    }
    
    /// Remove the specified lock from the cache and keychain.
    @discardableResult
    func remove(_ lock: UUID) -> Bool {
        
        guard let lockCache = self[lock: lock]
            else { return false }
        
        self[lock: lock] = nil
        self[key: lockCache.key.id] = nil
        
        return true
    }
    
    /// Get credentials from Keychain to authorize requests.
    func key(for lock: UUID) -> KeyCredentials? {
        guard let cache = self[lock: lock],
            let keyData = self[key: cache.key.id]
            else { return nil }
        return .init(id: cache.key.id, secret: keyData)
    }
    
    func key(for peripheral: NativeCentral.Peripheral) throws -> KeyCredentials {
        guard let information = self.lockInformation[peripheral] else {
            throw LockError.unknownLock(peripheral)
        }
        guard let key = self.key(for: information.id) else {
            throw LockError.noKey(lock: information.id)
        }
        return key
    }
    
    /// Private Key for the specified lock.
    subscript (key id: UUID) -> KeyData? {
        
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
}

// MARK: - Application Data

public extension Store {
    
    private func updateCaches() async {
        await updateCoreData()
        #if canImport(CoreSpotlight) && os(iOS) || os(macOS)
        // update Spotlight
        await updateSpotlight()
        #endif
    }
    
    private func lockCacheChanged() async {
        
        // update CoreData
        await updateCaches()
        // sync with iCloud
        await updateCloud()
    }
    
    var applicationData: ApplicationData {
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
            let oldValue = fileManager.applicationData
            guard oldValue != newValue else {
                return
            }
            // write file
            fileManager.applicationData = newValue
            // emit combine change
            objectWillChange.send()
            // update CoreData and CloudKit
            Task {
                await lockCacheChanged()
            }
        }
    }
    
    /// Cached information for the specified lock.
    subscript (lock id: UUID) -> LockCache? {
        get { return applicationData[lock: id] }
        set { applicationData[lock: id] = newValue }
    }
}

// MARK: - Spotlight

#if canImport(CoreSpotlight) && os(iOS) || os(macOS)
private extension Store {
    
    func updateSpotlight() async {
        guard SpotlightController.isSupported else { return }
        let locks = self.applicationData.locks
        do { try await spotlight.reindexAll(locks: locks) }
        catch { log("⚠️ Unable to update Spotlight: \(error.localizedDescription)") }
    }
}
#endif

// MARK: - CoreData

internal extension Store {
    
    func updateCoreData() async {
        let locks = self.applicationData.locks
        await backgroundContext.commit {
            try $0.insert(locks)
        }
    }
    
    func loadPersistentStore() {
        // load CoreData
        let semaphore = DispatchSemaphore(value: 0)
        persistentContainer.loadPersistentStores { (store, error) in
            defer { semaphore.signal() }
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
    }
}

// MARK: - Bluetooth Methods

public extension Store {
    
    private func observeBluetoothState() {
        // observe state
        Task { [weak self] in
            while let self = self {
                let newState = await self.central.state
                let oldValue = self.state
                if newState != oldValue {
                    self.state = newState
                }
                try await Task.sleep(timeInterval: 0.5)
            }
        }
    }
    
    /// The Bluetooth LE peripheral for the speciifed lock.
    subscript (peripheral id: UUID) -> NativeCentral.Peripheral? {
        return lockInformation.first(where: { $0.value.id == id })?.key
    }
    
    @available(*, deprecated, message: "Scan for a specified duration instead")
    func scanDefault() {
        guard state == .poweredOn else {
            return
        }
        Task {
            let bluetoothState = await self.central.state
            guard bluetoothState == .poweredOn else {
                throw LockError.bluetoothUnavailable
            }
            self.isScanning = true
            if let stream = scanStream, stream.isScanning {
                return // already scanning
            }
            self.scanStream = nil
            let filterDuplicates = true //preferences.filterDuplicates
            self.peripherals.removeAll(keepingCapacity: true)
            self.stopScanning()
            self.isScanning = true
            let stream = central.scan(
                with: [LockService.uuid],
                filterDuplicates: filterDuplicates
            )
            self.scanStream = stream
            // process scanned devices
            Task {
                defer { Task { await MainActor.run { self.isScanning = false } } }
                do {
                    for try await scanData in stream {
                        guard let serviceUUIDs = scanData.advertisementData.serviceUUIDs,
                            serviceUUIDs.contains(LockService.uuid)
                            else { continue }
                        // cache found device
                        try? await Task.sleep(timeInterval: 0.6)
                        self.peripherals[scanData.peripheral] = scanData
                    }
                } catch {
                    log("⚠️ Unable to scan. \(error)")
                }
            }
            // stop scanning after 5 sec if need to read device info
            Task {
                let loading = {
                    self.peripherals
                        .keys
                        .filter { !self.lockInformation.keys.contains($0) }
                }
                try? await Task.sleep(timeInterval: 3)
                while self.isScanning, loading().isEmpty {
                    try? await Task.sleep(timeInterval: 2)
                }
                // stop scanning and load info for unknown devices
                self.stopScanning()
                await Task.bluetooth {
                    for peripheral in loading() {
                        self.stopScanning()
                        do {
                            let _ = try await self.readInformation(for: peripheral)
                        } catch {
                            log("⚠️ Unable to load information for peripheral \(peripheral). \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func scan(duration: TimeInterval) async throws {
        precondition(duration > 0.001)
        let bluetoothState = await central.state
        guard bluetoothState == .poweredOn else {
            throw LockError.bluetoothUnavailable
        }
        self.scanStream = nil
        let filterDuplicates = true //preferences.filterDuplicates
        self.peripherals.removeAll(keepingCapacity: true)
        stopScanning()
        isScanning = true
        let stream = central.scan(
            with: [LockService.uuid],
            filterDuplicates: filterDuplicates
        )
        self.scanStream = stream
        let task = Task { [unowned self] in
            defer { Task { await MainActor.run { self.isScanning = false } } }
            var peripherals = [NativePeripheral: ScanData<NativeCentral.Peripheral, NativeCentral.Advertisement>]()
            for try await scanData in stream {
                guard let serviceUUIDs = scanData.advertisementData.serviceUUIDs,
                      serviceUUIDs.contains(LockService.uuid)
                else { continue }
                // cache found device
                peripherals[scanData.peripheral] = scanData
            }
            return peripherals
        }
        try await Task.sleep(timeInterval: duration)
        stream.stop()
        let peripherals = try await task.value // throw errors
        self.peripherals = peripherals
        let loading = {
            self.peripherals
                .keys
                .filter { !self.lockInformation.keys.contains($0) }
        }
        for peripheral in loading() {
            do {
                let _ = try await self.readInformation(for: peripheral)
            } catch {
                log("⚠️ Unable to load information for peripheral \(peripheral). \(error)")
            }
        }
    }
    
    func device(
        for id: UUID,
        scanDuration duration: TimeInterval = 2.0
    ) async throws -> NativeCentral.Peripheral? {
        stopScanning()
        if let peripheral = self[peripheral: id] {
            return peripheral
        } else {
            let filterDuplicates = true //preferences.filterDuplicates
            let stream = central.scan(
                with: [LockService.uuid],
                filterDuplicates: filterDuplicates
            )
            self.scanStream = stream
            self.isScanning = true
            Task {
                try? await Task.sleep(timeInterval: duration)
                stopScanning()
            }
            for try await scanData in stream {
                guard let serviceUUIDs = scanData.advertisementData.serviceUUIDs,
                    serviceUUIDs.contains(LockService.uuid)
                    else { continue }
                self.peripherals[scanData.peripheral] = scanData
                let peripheral = scanData.peripheral
                // if found and information has cached, stop scanning
                if let information = lockInformation[peripheral],
                    information.id == id {
                    stopScanning()
                    return peripheral // return first found device
                }
            }
            self.isScanning = false
            // scan stopped due to timeout
            for peripheral in peripherals.keys {
                // skip known locks that are not the targeted device
                if let information = lockInformation[peripheral] {
                    guard information.id == id else { continue }
                }
                // request information
                do {
                    let _ = try await self.readInformation(for: peripheral)
                } catch {
                    log("⚠️ Could not read information: \(error.localizedDescription)")
                    continue // ignore
                }
                if let foundDevice = self[peripheral: id] {
                    return foundDevice
                }
            }
            return self[peripheral: id]
        }
    }
    
    func stopScanning() {
        scanStream?.stop()
        scanStream = nil
        isScanning = false
    }
    
    @discardableResult
    func readInformation(for peripheral: NativePeripheral) async throws -> LockInformation {
        guard await central.state == .poweredOn else {
            throw LockError.bluetoothUnavailable
        }
        // stop scanning
        stopScanning()
        let information = try await central.connection(for: peripheral) {
            try await self.readInformation(for: $0)
        }
        return information
    }
    
    @discardableResult
    func readInformation(for connection: GATTConnection<NativeCentral>) async throws -> LockInformation {
        let information = try await connection.readInformation()
        // update lock information cache
        self.lockInformation[connection.peripheral] = information
        self[lock: information.id]?.information = LockCache.Information(information)
        log("Read information for \(information.id)")
        return information
    }
    
    /// Setup a lock.
    func setup(
        for lock: NativePeripheral,
        using sharedSecret: KeyData,
        name: String
    ) async throws {
        stopScanning()
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
        log("Finished setup for \(information.id)")
    }
    
    func unlock(
        for lock: UUID,
        action: UnlockAction = .default
    ) async throws {
        stopScanning()
        // get lock key
        guard let key = self.key(for: lock) else {
            throw LockError.noKey(lock: lock)
        }
        // scan for lock
        guard let peripheral = try await self.device(for: lock) else {
            throw LockError.notInRange(lock: lock)
        }
        // connect to device
        try await central.unlock(
            action,
            using: key,
            for: peripheral
        )
        log("Unlocked \(lock)")
    }
    
    func newKey(
        for peripheral: NativePeripheral,
        permission: Permission,
        name newKeyName: String
    ) async throws -> NewKey.Invitation {
        // get lock key
        guard let information = self.lockInformation[peripheral] else {
            throw LockError.unknownLock(peripheral)
        }
        let lockIdentifier = information.id
        guard let lockCache = self[lock: lockIdentifier],
            let parentKeyData = self[key: lockCache.key.id] else {
            throw LockError.noKey(lock: lockIdentifier)
        }
        let newKeyIdentifier = UUID()
        let parentKey = KeyCredentials(
            id: lockCache.key.id,
            secret: parentKeyData
        )
        let newKey = NewKey(
            id: newKeyIdentifier,
            name: newKeyName,
            permission: permission
        )
        let newKeySharedSecret = KeyData()
        // file for sharing
        let newKeyInvitation = NewKey.Invitation(
            lock: lockIdentifier,
            key: newKey,
            secret: newKeySharedSecret
        )
        let newKeyRequest = CreateNewKeyRequest(
            key: newKey,
            secret: newKeySharedSecret
        )
        try await central.createKey(
            newKeyRequest,
            using: parentKey,
            for: peripheral
        )
        log("Created new key \(newKey.id) (\(newKey.permission.type))")
        return newKeyInvitation
    }
    
    func confirm(_ newKeyInvitation: NewKey.Invitation, name: String) async throws {
        guard applicationData.locks[newKeyInvitation.lock] == nil else {
            throw LockError.existingKey(lock: newKeyInvitation.lock)
        }
        guard newKeyInvitation.key.expiration.timeIntervalSinceNow > 0 else {
            throw LockError.newKeyExpired
        }
        let keyData = KeyData()
        // recieve new key
        let credentials = KeyCredentials(
            id: newKeyInvitation.key.id,
            secret: newKeyInvitation.secret
        )
        let lock = newKeyInvitation.lock
        guard let peripheral = try await device(for: lock) else {
            throw LockError.notInRange(lock: lock)
        }
        guard let information = lockInformation[peripheral] else {
            assertionFailure("Should have information cached")
            throw LockError.unknownLock(peripheral)
        }
        // BLE request
        try await central.confirmKey(
            .init(secret: keyData),
            using: credentials,
            for: peripheral
        )
        // save data
        let lockCache = LockCache(
            key: Key(
                id: newKeyInvitation.key.id,
                name: newKeyInvitation.key.name,
                created: newKeyInvitation.key.created,
                permission: newKeyInvitation.key.permission
            ),
            name: name,
            information: .init(information)
        )
        self[lock: newKeyInvitation.lock] = lockCache
        self[key: newKeyInvitation.key.id] = keyData
        log("Confirmed new key for lock \(information.id)")
    }
    
    @discardableResult
    func listKeys(
        for peripheral: NativeCentral.Peripheral
    ) async throws -> KeysList {
        stopScanning()
        return try await central.connection(for: peripheral) {
            try await self.listKeys(for: $0)
        }
    }
    
    @discardableResult
    func listKeys(
        for connection: GATTConnection<NativeCentral>
    ) async throws -> KeysList {
        let peripheral = connection.peripheral
        // get lock key
        guard let information = self.lockInformation[peripheral] else {
            throw LockError.unknownLock(peripheral)
        }
        let lockIdentifier = information.id
        guard let lockCache = self[lock: lockIdentifier],
            let keyData = self[key: lockCache.key.id] else {
            throw LockError.noKey(lock: lockIdentifier)
        }
        let key = KeyCredentials(
            id: lockCache.key.id,
            secret: keyData
        )
        
        let context = backgroundContext
        var keysList = KeysList()
        // BLE request
        let centralLog = central.log
        let stream = try await connection.listKeys(using: key, log: centralLog)
        for try await notification in stream {
            switch notification.key {
            case let .key(key):
                centralLog?("Recieved \(key.permission.type) key \(key.id) \(key.name)")
            case let .newKey(key):
                centralLog?("Recieved \(key.permission.type) pending key \(key.id) \(key.name)")
            }
            //
            keysList.append(notification.key)
            // insert key to CoreData
            await context.commit { (context) in
                try context.insert(notification.key, for: information.id)
            }
        }
        
        // remove other keys from CoreData
        let coreDataTask = Task {
            await context.commit { (context) in
                do {
                    let fetchRequest = KeyManagedObject.fetchRequest()
                    let predicate = (
                        (#keyPath(KeyManagedObject.lock.identifier) == lockIdentifier)
                        && .compound(.not(
                            .comparison(
                                Comparison(
                                    left: .value(.collection(keysList.keys.map { .uuid($0.id) })),
                                    right: .keyPath(#keyPath(KeyManagedObject.identifier)),
                                    type: .contains
                                )
                            )
                        ))
                    )
                    fetchRequest.predicate = predicate.toFoundation()
                    assert(NSPredicate(
                        format: "%K == %@ && NOT %@ CONTAINS %K",
                        #keyPath(KeyManagedObject.lock.identifier),
                        lockIdentifier as NSUUID,
                        keysList.keys.map({ $0.id }) as NSArray,
                        #keyPath(KeyManagedObject.identifier)
                    ).description == predicate.description)
                    assert(predicate.description == predicate.toFoundation().description)
                    // fetch
                    let invalidKeys = try context.fetch(fetchRequest)
                    // remove keys from CoreData
                    invalidKeys.forEach {
                        context.delete($0)
                    }
                    if invalidKeys.isEmpty == false {
                        log("Removed \(invalidKeys.count) invalid keys from cache")
                    }
                }
                
                do {
                    let fetchRequest = NewKeyManagedObject.fetchRequest()
                    let predicate = (
                        (#keyPath(NewKeyManagedObject.lock.identifier) == lockIdentifier)
                        && .compound(.not(
                            .comparison(
                                Comparison(
                                    left: .value(.collection(keysList.newKeys.map { .uuid($0.id) })),
                                    right: .keyPath(#keyPath(NewKeyManagedObject.identifier)),
                                    type: .contains
                                )
                            )
                        ))
                    )
                    fetchRequest.predicate = predicate.toFoundation()
                    assert(NSPredicate(
                        format: "%K == %@ && NOT %@ CONTAINS %K",
                        #keyPath(NewKeyManagedObject.lock.identifier),
                        lockIdentifier as NSUUID,
                        keysList.newKeys.map { $0.id } as NSArray,
                        #keyPath(NewKeyManagedObject.identifier)
                    ).description == predicate.description)
                    // fetch
                    let invalidKeys = try context.fetch(fetchRequest)
                    // remove keys from CoreData
                    invalidKeys.forEach {
                        context.delete($0)
                    }
                    if invalidKeys.isEmpty == false {
                        log("Removed \(invalidKeys.count) invalid pending keys from cache")
                    }
                }
            }
        }
        
        // wait until that finishes
        await coreDataTask.value
        
        objectWillChange.send()
        
        // upload keys to cloud
        Task {
            await updateCloud()
        }
        
        log("Recieved \(keysList.keys.count) keys and \(keysList.newKeys.count) pending keys for lock \(information.id)")
        
        return keysList
    }
    
    @discardableResult
    func listEvents(
        for peripheral: NativePeripheral,
        fetchRequest: LockEvent.FetchRequest? = nil
    ) async throws -> [LockEvent] {
        stopScanning()
        return try await central.connection(for: peripheral) {
            try await self.listEvents(for: $0, fetchRequest: fetchRequest)
        }
    }
    
    @discardableResult
    func listEvents(
        for connection: GATTConnection<NativeCentral>,
        fetchRequest: LockEvent.FetchRequest? = nil
    ) async throws -> [LockEvent] {
        let peripheral = connection.peripheral
        // get lock key
        guard let information = self.lockInformation[peripheral] else {
            throw LockError.unknownLock(peripheral)
        }
        let lockIdentifier = information.id
        guard let lockCache = self[lock: lockIdentifier],
            let keyData = self[key: lockCache.key.id] else {
            throw LockError.noKey(lock: lockIdentifier)
        }
        let key = KeyCredentials(
            id: lockCache.key.id,
            secret: keyData
        )
        
        let context = backgroundContext
        var events = [LockEvent]()
        events.reserveCapacity(Int(fetchRequest?.limit ?? 10))
        // BLE request
        let centralLog = central.log
        let stream = try await connection.listEvents(
            fetchRequest: fetchRequest,
            using: key,
            log: centralLog
        )
        for try await notification in stream {
            guard let event = notification.event else {
                break
            }
            centralLog?("Recieved \(event.type) event \(event.id)")
            events.append(event)
            // store in CoreData
            await context.commit { (context) in
                try context.insert(event, for: information.id)
            }
            // upload to iCloud
            if preferences.isCloudBackupEnabled {
                // perform concurrently
                Task {
                    let value = LockEvent.Cloud(event: event, for: lockIdentifier)
                    try await self.cloud.upload(value)
                }
            }
        }
        
        objectWillChange.send()
        
        log("Recieved \(events.count) events for lock \(information.id)")
        return events
    }
}
