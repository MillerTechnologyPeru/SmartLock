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
    
    /// Retreive a list of all keys on device.
    public func listKeys(for peripheral: Peripheral,
                         with key: KeyCredentials,
                         timeout: TimeInterval = .gattDefaultTimeout) throws -> KeysList {
        
        var keys = KeysList()
        try listKeys(for: peripheral,
                     with: key,
                     notification: { (newValue, _) in keys = newValue },
                     timeout: timeout)
        return keys
    }
    
    /// Retreive a list of all keys on device.
    public func listKeys(for peripheral: Peripheral,
                         with key: KeyCredentials,
                         notification: (KeysList, Bool) -> (),
                         timeout: TimeInterval = .gattDefaultTimeout) throws {
        
        typealias Notification = KeysCharacteristic
        
        let timeout = Timeout(timeout: timeout)
        
        try central.device(for: peripheral, timeout: timeout) { [unowned self] (cache) in
            
            let semaphore = Semaphore(timeout: timeout.timeout)
            
            var chunks = [Chunk]()
            chunks.reserveCapacity(2)
            var lastKeyNotification: KeyListNotification?
            var keysList = KeysList(
                keys: .init(reserveCapacity: 2),
                newKeys: .init(reserveCapacity: 1)
            )
            
            // notify
            try self.central.notify(Notification.self, for: cache, timeout: timeout) { (response) in
                
                switch response {
                case let .error(error):
                    semaphore.stopWaiting(error)
                case let .value(value):
                    let chunk = value.chunk
                    self.log?("Received chunk \(chunks.count + 1) (\(chunk.bytes.count) bytes)")
                    chunks.append(chunk)
                    semaphore.stopWaiting()
                }
            }
            
            let characteristicValue = ListKeysCharacteristic(
                identifier: key.identifier,
                authentication: Authentication(key: key.secret)
            )
            
            // Write data to characteristic
            try self.central.write(characteristicValue, for: cache, timeout: timeout)
            
            // handle disconnect
            self.central.didDisconnect = {
                guard $0 == cache.peripheral else { return }
                semaphore.stopWaiting(CentralError.disconnected)
            }
            
            // wait for notifications
            try semaphore.wait() // wait for first notification
            while let lastChunk = chunks.last {
                if chunks.length < lastChunk.total {
                    // keep on waiting for more chunks
                    try semaphore.wait()
                } else {
                    let notificationValue = try KeysCharacteristic.from(chunks: chunks, secret: key.secret)
                    chunks.removeAll(keepingCapacity: true)
                    lastKeyNotification = notificationValue
                    keysList.append(notificationValue.key)
                    self.log?("Recieved key \(notificationValue.key.identifier)")
                    notification(keysList, notificationValue.isLast)
                    if notificationValue.isLast {
                        // finished loading keys
                        assert(keysList.isEmpty == false)
                        assert(lastKeyNotification != nil)
                        assert(lastKeyNotification?.isLast ?? true, "Invalid last notification")
                    } else {
                        try semaphore.wait() // wait for more next key
                    }
                }
            }
            
            assert(keysList.isEmpty == false)
            assert(lastKeyNotification != nil)
            assert(lastKeyNotification?.isLast ?? true, "Invalid last notification")
            
            // ignore disconnection
            central.didDisconnect = nil
            
            // stop notifications
            try self.central.notify(Notification.self, for: cache, timeout: Timeout(timeout: timeout.timeout), notification: nil)
        }
    }
    
    /// Remove the specified key. 
    public func removeKey(_ identifier: UUID,
                          type: KeyType = .key,
                          for peripheral: Peripheral,
                          with key: KeyCredentials,
                          timeout: TimeInterval = .gattDefaultTimeout) throws {
        
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
}

// MARK: - Supporting Types

public struct LockPeripheral <Central: CentralProtocol> {
    
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
