//
//  Store.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import Foundation
import Combine
@_exported import Bluetooth
@_exported import GATT
@_exported import CoreLock
import DarwinGATT
import KeychainAccess

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
    public var peripherals = [NativePeripheral: ScanData<NativeCentral.Peripheral, NativeCentral.Advertisement>]()
    
    @Published
    public var lockInformation = [NativePeripheral: LockInformation]()
    
    public lazy var central = DarwinCentral()
    
    private var scanStream: AsyncCentralScan<DarwinCentral>?
    
    internal lazy var keychain = Keychain(service: .lock, accessGroup: .lock)
    
    internal lazy var fileManager: FileManager.Lock = .shared
    
    // MARK: - Initialization
    
    private init() {
        // setup logging
        central.log = { log("📲 Central: " + $0) }
        
        // observe state
        Task { [weak self] in
            while let self = self {
                let newState = await self.central.state
                let oldValue = self.state
                if newState != oldValue {
                    self.state = newState
                    if newState == .poweredOn, isScanning == false {
                        await self.scan()
                    }
                }
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
}

// MARK: - Keychain

public extension Store {
    
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

// MARK: - File Methods

public extension Store {
    
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
            objectWillChange.send()
            fileManager.applicationData = newValue
        }
    }
    
    /// Cached information for the specified lock.
    subscript (lock id: UUID) -> LockCache? {
        get { return applicationData[lock: id] }
        set { applicationData[lock: id] = newValue }
    }
}

// MARK: - Bluetooth Methods

public extension Store {
    
    /// The Bluetooth LE peripheral for the speciifed lock.
    subscript (peripheral id: UUID) -> NativeCentral.Peripheral? {
        return lockInformation.first(where: { $0.value.id == id })?.key
    }
    
    func scan() async {
        guard await central.state == .poweredOn else {
            isScanning = false
            return
        }
        isScanning = true
        if let stream = scanStream, stream.isScanning {
            return // already scanning
        }
        let scanStart = Date()
        self.scanStream = nil
        let filterDuplicates = true //preferences.filterDuplicates
        self.peripherals.removeAll(keepingCapacity: true)
        let stream = central.scan(
            with: [LockService.uuid],
            filterDuplicates: filterDuplicates
        )
        self.scanStream = stream
        // process scanned devices
        Task {
            do {
                for try await scanData in stream {
                    guard let serviceUUIDs = scanData.advertisementData.serviceUUIDs,
                        serviceUUIDs.contains(LockService.uuid)
                        else { continue }
                    // cache found device
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    self.peripherals[scanData.peripheral] = scanData
                }
            } catch {
                log("⚠️ Unable to scan. \(error)")
            }
            isScanning = false
        }
        // stop scanning after 5 sec if need to read device info
        Task {
            let loading = {
                self.peripherals
                    .keys
                    .filter { !self.lockInformation.keys.contains($0) }
            }
            try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            while self.isScanning, loading().isEmpty {
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            }
            // stop scanning and load info for unknown devices
            stopScanning()
            for peripheral in loading() {
                do {
                    let information = try await self.readInformation(for: peripheral)
                    log("Read information for lock \(information.id)")
                    #if DEBUG
                    dump(information)
                    #endif
                } catch {
                    log("⚠️ Unable to load information for peripheral \(peripheral). \(error)")
                }
            }
        }
    }
    
    func scan(duration: TimeInterval) async {
        await scan()
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration) * 1_000_000_000)
            stopScanning()
        }
    }
    
    func stopScanning() {
        scanStream?.stop()
        scanStream = nil
        isScanning = false
    }
    
    @discardableResult
    func readInformation(for peripheral: DarwinCentral.Peripheral) async throws -> LockInformation {
        guard await central.state == .poweredOn else {
            throw LockError.bluetoothUnavailable
        }
        // stop scanning
        if isScanning {
            stopScanning()
        }
        let information = try await central.readInformation(
            for: peripheral
        )
        // update lock information cache
        self.lockInformation[peripheral] = information
        self[lock: information.id]?.information = LockCache.Information(information)
        return information
    }
    
    /// Setup a lock.
    func setup(
        for lock: DarwinCentral.Peripheral,
        using sharedSecret: KeyData,
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
    
    func unlock(
        for lock: DarwinCentral.Peripheral,
        action: UnlockAction = .default
    ) async throws {
        // get lock key
        let key = try self.key(for: lock)
        try await central.unlock(
            action,
            using: key,
            for: lock
        )
    }
}
