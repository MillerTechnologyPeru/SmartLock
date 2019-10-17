//
//  DeviceManager.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/8/18.
//

import Foundation
import Bluetooth
import GATT

/// SmartLock GATT Central client.
public final class LockManager <Central: CentralProtocol> {
    
    public typealias Peripheral = Central.Peripheral
    
    public typealias Advertisement = Central.Advertisement
    
    // MARK: - Initialization
    
    public init(central: Central) {
        
        self.central = central
    }
    
    // MARK: - Properties
    
    /// GATT Central Manager.
    public let central: Central
    
    /// The log message handler.
    public var log: ((String) -> ())?
    
    /// Scans for nearby devices.
    ///
    /// - Parameter duration: The duration of the scan.
    ///
    /// - Parameter event: Callback for a found device.
    public func scan(duration: TimeInterval,
                     filterDuplicates: Bool = false,
                     event: @escaping ((LockPeripheral<Central>) -> ())) throws {
        
        log?("Scanning for \(String(format: "%.2f", duration))s")
        
        try central.scan(duration: duration, filterDuplicates: filterDuplicates) { (scanData) in
            
            // filter peripheral
            guard let lock = LockPeripheral<Central>(scanData)
                else { return }
            
            event(lock)
        }
    }
    
    /// Scans for nearby devices.
    ///
    /// - Parameter event: Callback for a found device.
    ///
    /// - Parameter scanMore: Callback for determining whether the manager
    /// should continue scanning for more devices.
    public func scan(filterDuplicates: Bool = false,
                     event: @escaping ((LockPeripheral<Central>) -> ())) throws {
        
        log?("Scanning...")
        
        try self.central.scan(filterDuplicates: filterDuplicates) { (scanData) in
            
            // filter peripheral
            guard let lock = LockPeripheral<Central>(scanData)
                else { return }
            
            event(lock)
        }
    }
    
    /// Read the lock's information characteristic.
    public func readInformation(for peripheral: Peripheral,
                                timeout: TimeInterval = .gattDefaultTimeout) throws -> LockInformationCharacteristic {
        
        log?("Read information for \(peripheral)")
        
        let timeout = Timeout(timeout: timeout)
        
        return try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            
            return try self.readInformation(cache: cache, timeout: timeout)
        }
    }
    
    internal func readInformation(cache: GATTConnectionCache<Peripheral>,
                                  timeout: Timeout) throws -> LockInformationCharacteristic {
        
        return try central.read(LockInformationCharacteristic.self, for: cache, timeout: timeout)
    }
    
    /// Setup a lock.
    public func setup(_ request: SetupRequest,
                      for peripheral: Peripheral,
                      sharedSecret: KeyData,
                      timeout: TimeInterval = .gattDefaultTimeout) throws -> LockInformationCharacteristic {
        
        log?("Setup \(peripheral)")
        
        let timeout = Timeout(timeout: timeout)
        
        return try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            
            // encrypt owner key data
            let characteristicValue = try SetupCharacteristic(request: request,
                                                              sharedSecret: sharedSecret)
            
            // write setup characteristic
            try self.central.write(characteristicValue, for: cache, timeout: timeout)
            
            // read information
            let information = try self.readInformation(cache: cache, timeout: timeout)
            
            guard information.status == .unlock
                else { throw GATTError.couldNotComplete }
            
            return information
        }
    }
    
    /// Unlock action.
    public func unlock(_ action: UnlockAction = .default,
                       for peripheral: Peripheral,
                       with key: KeyCredentials,
                       timeout: TimeInterval = .gattDefaultTimeout) throws {
        
        log?("Unlock \(peripheral) with action \(action)")
        
        let timeout = Timeout(timeout: timeout)
        
        try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            
            let characteristicValue = UnlockCharacteristic(identifier: key.identifier,
                                                           action: action,
                                                           authentication: Authentication(key: key.secret))
            
            // Write unlock data to characteristic
            try self.central.write(characteristicValue, for: cache, timeout: timeout)
        }
    }
    
    /// Create new key.
    public func createKey(_ newKey: CreateNewKeyRequest,
                          for peripheral: Peripheral,
                          with key: KeyCredentials,
                          timeout: TimeInterval = .gattDefaultTimeout) throws {
        
        log?("Create \(newKey.permission.type) key \"\(newKey.name)\" \(newKey.identifier)")
        
        let timeout = Timeout(timeout: timeout)
        
        try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            
            let characteristicValue = try CreateNewKeyCharacteristic(
                request: newKey,
                for: key.identifier,
                sharedSecret: key.secret
            )
            
            // Write data to characteristic
            try self.central.write(characteristicValue, for: cache, timeout: timeout)
        }
    }
    
    /// Confirm new key.
    public func confirmKey(_ confirmation: ConfirmNewKeyRequest,
                           for peripheral: Peripheral,
                           with key: KeyCredentials,
                           timeout: TimeInterval = .gattDefaultTimeout) throws {
        
        log?("Confirm key \(key.identifier)")
        
        let timeout = Timeout(timeout: timeout)
        
        try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            
            let characteristicValue = try ConfirmNewKeyCharacteristic(
                request: confirmation,
                for: key.identifier,
                sharedSecret: key.secret
            )
            
            // Write data to characteristic
            try self.central.write(characteristicValue, for: cache, timeout: timeout)
        }
    }
    
    /// Remove the specified key. 
    public func removeKey(_ identifier: UUID,
                          type: KeyType = .key,
                          for peripheral: Peripheral,
                          with key: KeyCredentials,
                          timeout: TimeInterval = .gattDefaultTimeout) throws {
        
        log?("Remove \(type) \(identifier)")
        
        let timeout = Timeout(timeout: timeout)
        
        try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            
            let characteristicValue = RemoveKeyCharacteristic(identifier: key.identifier,
                                                              key: identifier,
                                                              type: type,
                                                              authentication: Authentication(key: key.secret))
            
            // Write unlock data to characteristic
            try self.central.write(characteristicValue, for: cache, timeout: timeout)
        }
    }
    
    internal func list <Write, Notify> (write: @autoclosure () -> (Write),
                                        notify: Notify.Type,
                                        for peripheral: Peripheral,
                                        with key: KeyCredentials,
                                        timeout: TimeInterval,
                                        notification: @escaping (Notify.Notification) -> ()) throws
        where Write: GATTCharacteristic, Notify: GATTEncryptedNotification {
        
        let timeout = Timeout(timeout: timeout)
        try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            let semaphore = Semaphore(timeout: timeout.timeout)
            var chunks = [Chunk]()
            chunks.reserveCapacity(2)
            var lastNotification: Notify.Notification?
            // notify
            try self.central.notify(Notify.self, for: cache, timeout: timeout) { (response) in
                switch response {
                case let .error(error):
                    semaphore.stopWaiting(error)
                case let .value(value):
                    let chunk = value.chunk
                    self.log?("Received chunk \(chunks.count + 1) (\(chunk.bytes.count) bytes)")
                    chunks.append(chunk)
                    assert(chunks.isEmpty == false)
                    guard chunks.length >= chunk.total
                        else { return }// wait for more chunks
                    do {
                        let notificationValue = try Notify.from(chunks: chunks, secret: key.secret)
                        chunks.removeAll(keepingCapacity: true)
                        lastNotification = notificationValue
                        notification(notificationValue)
                        if notificationValue.isLast {
                            semaphore.stopWaiting()
                        }
                    } catch {
                        semaphore.stopWaiting(error)
                    }
                }
            }
            
            // Write data to characteristic
            try self.central.write(write(), for: cache, timeout: timeout)
            
            // handle disconnect
            self.central.didDisconnect = {
                guard $0 == cache.peripheral else { return }
                semaphore.stopWaiting(CentralError.disconnected)
            }
            
            /// Wait for all pending notifications
            while (lastNotification?.isLast ?? false) == false {
                try semaphore.wait() // wait for notification
            }
            
            assert(lastNotification != nil)
            assert(lastNotification?.isLast ?? true, "Invalid last notification")
            
            // ignore disconnection
            central.didDisconnect = nil
            
            // stop notifications
            try self.central.notify(Notify.self, for: cache, timeout: Timeout(timeout: timeout.timeout), notification: nil)
        }
    }
    
    /// Retreive a list of all keys on device.
    public func listKeys(for peripheral: Peripheral,
                         with key: KeyCredentials,
                         timeout: TimeInterval = .gattDefaultTimeout) throws -> KeysList {
        
        var list = KeysList()
        try listKeys(for: peripheral,
                     with: key,
                     timeout: timeout,
                     notification: { (newValue, isLast) in if isLast { list = newValue } })
        return list
    }
    
    /// Retreive a list of all keys on device.
    public func listKeys(for peripheral: Peripheral,
                         with key: KeyCredentials,
                         timeout: TimeInterval = .gattDefaultTimeout,
                         notification: @escaping (KeysList, Bool) -> ()) throws {
        
        log?("List keys for \(peripheral)")
        typealias Notification = KeysCharacteristic
        var keysList = KeysList()
        try list(write: ListKeysCharacteristic(
            identifier: key.identifier,
            authentication: Authentication(key: key.secret)
        ), notify: Notification.self, for: peripheral, with: key, timeout: timeout) { [unowned self] (notificationValue) in
            keysList.append(notificationValue.key)
            self.log?("Recieved key \(notificationValue.key.identifier)")
            notification(keysList, notificationValue.isLast)
        }
        assert(keysList.isEmpty == false)
    }
    
    /// Retreive a list of events on device.
    public func listEvents(fetchRequest: LockEvent.FetchRequest? = nil,
                           for peripheral: Peripheral,
                           with key: KeyCredentials,
                           timeout: TimeInterval = .gattDefaultTimeout) throws -> EventsList {
        
        var list = EventsList()
        try listEvents(fetchRequest: fetchRequest,
                       for: peripheral,
                       with: key,
                       timeout: timeout,
                       notification: { (newValue, isLast) in if isLast { list = newValue } })
        return list
    }
    
    /// Retreive a list of events on device.
    public func listEvents(fetchRequest: LockEvent.FetchRequest? = nil,
                           for peripheral: Peripheral,
                           with key: KeyCredentials,
                           timeout: TimeInterval = .gattDefaultTimeout,
                           notification: @escaping (EventsList, Bool) -> ()) throws {
        
        log?("List events for \(peripheral)")
        typealias Notification = EventsCharacteristic
        var events = EventsList()
        events.reserveCapacity(fetchRequest?.limit.flatMap({ Int($0) }) ?? 1)
        try list(write: ListEventsCharacteristic(
            identifier: key.identifier,
            authentication: Authentication(key: key.secret),
            fetchRequest: fetchRequest
        ), notify: Notification.self, for: peripheral, with: key, timeout: timeout) { [unowned self] (notificationValue) in
            if let event = notificationValue.event {
                events.append(event)
                self.log?("Recieved event \(event.identifier)")
            }
            notification(events, notificationValue.isLast)
        }
    }
}

#if canImport(DarwinGATT)
import DarwinGATT

public extension LockManager where Central == DarwinCentral {
    
    /// Scans for nearby devices.
    ///
    /// - Parameter duration: The duration of the scan.
    ///
    /// - Parameter event: Callback for a found device.
    func scanLocks(filterDuplicates: Bool = false,
                   event: @escaping (LockPeripheral<Central>) -> ()) throws {
        
        log?("Scanning...")
        
        try central.scan(filterDuplicates: filterDuplicates, with: [LockService.uuid]) { (scanData) in
            
            // filter peripheral
            guard let lock = LockPeripheral<Central>(scanData)
                else { return }
            
            event(lock)
        }
    }
    
    /// Scans for peripherals that are advertising services for the specified time interval.
    func scanLocks(duration: TimeInterval,
                   filterDuplicates: Bool = false,
                   event: @escaping (LockPeripheral<Central>) -> ()) throws {
        
        log?("Scanning for \(String(format: "%.2f", duration))s")
        
        var didThrow = false
        DispatchQueue.global().asyncAfter(deadline: .now() + duration) { [weak self] in
            if didThrow == false {
                self?.central.stopScan()
            }
        }
        
        do { try scanLocks(filterDuplicates: filterDuplicates, event: event) }
        catch {
            didThrow = true
            throw error
        }
    }
}

#endif

// MARK: - Supporting Types

public struct LockPeripheral <Central: CentralProtocol>: Equatable {
    
    /// Scan Data
    public let scanData: ScanData<Central.Peripheral, Central.Advertisement>
    
    /// Initialize from scan data.
    internal init?(_ scanData: ScanData<Central.Peripheral, Central.Advertisement>) {
        
        // filter peripheral
        guard let serviceUUIDs = scanData.advertisementData.serviceUUIDs, serviceUUIDs.contains(LockService.uuid)
            else { return nil }
        
        self.scanData = scanData
    }
}

public struct KeyCredentials: Equatable {
    
    public let identifier: UUID
    
    public let secret: KeyData
    
    public init(identifier: UUID, secret: KeyData) {
        self.identifier = identifier
        self.secret = secret
    }
}

internal final class Semaphore {
    
    let semaphore: DispatchSemaphore
    let timeout: TimeInterval
    private(set) var error: Swift.Error?
    
    init(timeout: TimeInterval) {
        
        self.timeout = timeout
        self.semaphore = DispatchSemaphore(value: 0)
        self.error = nil
    }
    
    func wait() throws {
        
        self.error = nil
        let dispatchTime: DispatchTime = .now() + timeout
        
        let success = semaphore.wait(timeout: dispatchTime) == .success
        
        if let error = self.error {
            throw error
        }
        
        guard success else { throw CentralError.timeout }
    }
    
    func stopWaiting(_ error: Swift.Error? = nil) {
        
        // store error
        self.error = error
        
        // stop blocking
        semaphore.signal()
    }
}
