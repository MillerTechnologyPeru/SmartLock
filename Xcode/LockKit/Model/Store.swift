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
import DarwinGATT
@_exported import CoreLock

/// Lock Store object
@MainActor
public final class Store: ObservableObject {
    
    public static let shared = Store()
    
    // MARK: - Properties
    
    @Published
    public internal(set) var isScanning = false
    
    @Published
    public var peripherals = [NativePeripheral: ScanData<NativeCentral.Peripheral, NativeCentral.Advertisement>]()
    
    @Published
    public var lockInformation = [NativePeripheral: LockInformation]()
    
    public lazy var central = DarwinCentral()
    
    private var scanStream: AsyncCentralScan<DarwinCentral>?
    
    // MARK: - Initialization
    
    private init() {
        _ = central
    }
    
}

// MARK: - Bluetooth Methods

public extension Store {
    
    func scan() async {
        isScanning = true
        let filterDuplicates = true //preferences.filterDuplicates
        self.peripherals.removeAll(keepingCapacity: true)
        let stream = central.scan(
            with: [LockService.uuid],
            filterDuplicates: filterDuplicates
        )
        self.scanStream = stream
        Task {
            do {
                for try await scanData in stream {
                    guard let serviceUUIDs = scanData.advertisementData.serviceUUIDs,
                        serviceUUIDs.contains(LockService.uuid)
                        else { continue }
                    // cache found device
                    self.peripherals[scanData.peripheral] = scanData
                }
            } catch {
                print("Scanning error \(error)")
            }
            isScanning = false
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
    
    func readInformation(_ lock: DarwinCentral.Peripheral) async throws {
                
        let information = try await central.readInformation(
            for: lock
        )
        
        // update lock information cache
        self.lockInformation[lock] = information
        //self[lock: information.id]?.information = LockCache.Information(information)
    }
    
    /// Setup a lock.
    func setup(
        _ lock: DarwinCentral.Peripheral,
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
        /*
        let lockCache = LockCache(
            key: ownerKey,
            name: name,
            information: .init(information)
        )
        
        // store key
        self[lock: information.id] = lockCache
        self[key: ownerKey.id] = setupRequest.secret
        */
        // update lock information
        self.lockInformation[lock] = information
    }
    
    func unlock(
        _ lock: DarwinCentral.Peripheral,
        action: UnlockAction = .default
    ) async throws {
        /*
        // get lock key
        guard let key = self.key(for: lock)
            else { return false }
        
        try await central.unlock(
            action,
            using: key,
            for: lock
        )
        */
    }
}
