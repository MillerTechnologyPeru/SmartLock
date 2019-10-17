//
//  LockServiceController.swift
//  CoreLockGATTServer
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth
import GATT
import CoreLock

public final class LockGATTServiceController <Peripheral: PeripheralProtocol> : GATTServiceController {
    
    public static var service: BluetoothUUID { return Service.uuid }
    
    public let characteristics: Set<BluetoothUUID>
    
    public typealias Service = LockService
        
    // MARK: - Properties
    
    public let peripheral: Peripheral
        
    public var hardware: LockHardware = .empty  {
        didSet { updateInformation() }
    }
    
    public var configurationStore: LockConfigurationStore = InMemoryLockConfigurationStore() {
        didSet { updateInformation() }
    }
        
    public var authorization: LockAuthorizationStore = InMemoryLockAuthorization() {
        didSet { updateInformation() }
    }
    
    public var setupSecret: KeyData = KeyData()
    
    public var unlockDelegate: UnlockDelegate = UnlockSimulator()
    
    public var events: LockEventStore = InMemoryLockEvents()
    
    public var lockChanged: (() -> ())?
    
    public var authorizationTimeout: TimeInterval = 10.0
    
    // handles
    internal let serviceHandle: UInt16
    internal let informationHandle: UInt16
    internal let setupHandle: UInt16
    internal let unlockHandle: UInt16
    internal let createNewKeyHandle: UInt16
    internal let confirmNewKeyHandle: UInt16
    internal let removeKeyHandle: UInt16
    internal let keysRequestHandle: UInt16
    internal let keysResponseHandle: UInt16
    internal let eventsRequestHandle: UInt16
    internal let eventsResponseHandle: UInt16
    
    // MARK: - Initialization
    
    public init(peripheral: Peripheral) throws {
        
        self.peripheral = peripheral
                
        let characteristics = [
            
            GATT.Characteristic(uuid: LockInformationCharacteristic.uuid,
                                value: Data(),
                                permissions: [.read],
                                properties: LockInformationCharacteristic.properties),
            
            GATT.Characteristic(uuid: SetupCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: SetupCharacteristic.properties),
            
            GATT.Characteristic(uuid: UnlockCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: UnlockCharacteristic.properties),
            
            GATT.Characteristic(uuid: CreateNewKeyCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: CreateNewKeyCharacteristic.properties),
            
            GATT.Characteristic(uuid: ConfirmNewKeyCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: ConfirmNewKeyCharacteristic.properties),
            
            GATT.Characteristic(uuid: RemoveKeyCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: RemoveKeyCharacteristic.properties),
            
            GATT.Characteristic(uuid: ListKeysCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: ListKeysCharacteristic.properties),
            
            GATT.Characteristic(uuid: KeysCharacteristic.uuid,
                                value: Data(),
                                permissions: [],
                                properties: KeysCharacteristic.properties,
                                descriptors: [GATTClientCharacteristicConfiguration().descriptor]),
            
            
            GATT.Characteristic(uuid: ListEventsCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: ListEventsCharacteristic.properties),
            
            GATT.Characteristic(uuid: EventsCharacteristic.uuid,
                                value: Data(),
                                permissions: [],
                                properties: EventsCharacteristic.properties,
                                descriptors: [GATTClientCharacteristicConfiguration().descriptor]),
        ]
        
        self.characteristics = Set(characteristics.map { $0.uuid })
        
        let service = GATT.Service(uuid: Service.uuid,
                                   primary: Service.isPrimary,
                                   characteristics: characteristics)
        
        self.serviceHandle = try peripheral.add(service: service)
        
        self.informationHandle = peripheral.characteristics(for: LockInformationCharacteristic.uuid)[0]
        self.setupHandle = peripheral.characteristics(for: SetupCharacteristic.uuid)[0]
        self.unlockHandle = peripheral.characteristics(for: UnlockCharacteristic.uuid)[0]
        self.createNewKeyHandle = peripheral.characteristics(for: CreateNewKeyCharacteristic.uuid)[0]
        self.confirmNewKeyHandle = peripheral.characteristics(for: ConfirmNewKeyCharacteristic.uuid)[0]
        self.removeKeyHandle = peripheral.characteristics(for: RemoveKeyCharacteristic.uuid)[0]
        self.keysRequestHandle = peripheral.characteristics(for: ListKeysCharacteristic.uuid)[0]
        self.keysResponseHandle = peripheral.characteristics(for: KeysCharacteristic.uuid)[0]
        self.eventsRequestHandle = peripheral.characteristics(for: ListEventsCharacteristic.uuid)[0]
        self.eventsResponseHandle = peripheral.characteristics(for: EventsCharacteristic.uuid)[0]
        
        updateInformation()
    }
    
    deinit {
        self.peripheral.remove(service: serviceHandle)
    }
    
    // MARK: - Methods
    
    public func reset() {
        
        try? authorization.removeAll()
        updateInformation()
    }
    
    public func willRead(_ request: GATTReadRequest<Peripheral.Central>) -> ATT.Error? {
        
        return nil
    }
    
    public func willWrite(_ request: GATTWriteRequest<Peripheral.Central>) -> ATT.Error? {
        
        switch request.handle {
        case setupHandle:
            return authorization.isEmpty ? nil : .writeNotPermitted
        case unlockHandle:
            return authorization.isEmpty ? .writeNotPermitted : nil
        case createNewKeyHandle:
            return authorization.isEmpty ? .writeNotPermitted : nil
        default:
            return nil
        }
    }
    
    public func didWrite(_ write: GATTWriteConfirmation<Peripheral.Central>) {
        
        switch write.handle {
            
        case setupHandle:
            
            precondition(authorization.isEmpty, "Already setup")
            
            // parse characteristic
            guard let characteristic = SetupCharacteristic(data: write.value)
                else { print("Could not parse \(SetupCharacteristic.self)"); return }
            
            setup(characteristic)
            
        case unlockHandle:
            
            assert(authorization.isEmpty == false, "No keys")
            
            // parse characteristic
            guard let characteristic = UnlockCharacteristic(data: write.value)
                else { print("Could not parse \(UnlockCharacteristic.self)"); return }
            
            unlock(characteristic)
            
        case createNewKeyHandle:
            
            assert(authorization.isEmpty == false, "No keys")
            
            // parse characteristic
            guard let characteristic = CreateNewKeyCharacteristic(data: write.value)
                else { print("Could not parse \(CreateNewKeyCharacteristic.self)"); return }
            
            createNewKey(characteristic)
            
        case confirmNewKeyHandle:
            
            assert(authorization.isEmpty == false, "No keys")
            
            // parse characteristic
            guard let characteristic = ConfirmNewKeyCharacteristic(data: write.value)
                else { print("Could not parse \(ConfirmNewKeyCharacteristic.self)"); return }
            
            confirmNewKey(characteristic)
            
        case removeKeyHandle:
            
            assert(authorization.isEmpty == false, "No keys")
            
            // parse characteristic
            guard let characteristic = RemoveKeyCharacteristic(data: write.value)
                else { print("Could not parse \(RemoveKeyCharacteristic.self)"); return }
            
            removeKey(characteristic)
            
        case keysRequestHandle:
            
            assert(authorization.isEmpty == false, "No keys")
            
            // parse characteristic
            guard let characteristic = ListKeysCharacteristic(data: write.value)
                else { print("Could not parse \(ListKeysCharacteristic.self)"); return }
            
            listKeysRequest(characteristic, maximumUpdateValueLength: write.maximumUpdateValueLength)
            
        case keysResponseHandle:
            assertionFailure("Not writable")
            
        case eventsRequestHandle:
            
            assert(authorization.isEmpty == false, "Not setup yet")
            
            // parse characteristic
            guard let characteristic = ListEventsCharacteristic(data: write.value)
                else { print("Could not parse \(ListEventsCharacteristic.self)"); return }
            
            listEventsRequest(characteristic, maximumUpdateValueLength: write.maximumUpdateValueLength)
            
        case eventsResponseHandle:
            assertionFailure("Not writable")
            
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func updateInformation() {
        
        let status: LockStatus = authorization.isEmpty ? .setup : .unlock
        
        let identifier = configurationStore.configuration.identifier
        
        let information = LockInformationCharacteristic(identifier: identifier,
                                                        buildVersion: .current,
                                                        version: .current,
                                                        status: status,
                                                        unlockActions: [.default])
        
        peripheral[characteristic: informationHandle] = information.data
    }
    
    private func setup(_ setup: SetupCharacteristic) {
        
        assert(authorization.isEmpty)
        
        // get key for shared device.
        let sharedSecret = setupSecret
        
        do {
            
            // guard against replay attacks
            let timestamp = setup.encryptedData.authentication.message.date
            let now = Date()
            guard timestamp <= now + authorizationTimeout, // cannot be used later for replay attacks
                timestamp > now - authorizationTimeout // only valid for 5 seconds
                else { print("Authentication expired \(timestamp) < \(now)"); return }
            
            // decrypt request
            let setupRequest = try setup.decrypt(with: sharedSecret)
            
            // create owner key
            let ownerKey = Key(setup: setupRequest)
            
            // store first key
            try authorization.add(ownerKey, secret: setupRequest.secret)
            assert(authorization.isEmpty == false)
            
            print("Lock setup completed")
            
            updateInformation()
            
            try events.save(.setup(.init(key: ownerKey.identifier)))
            
            lockChanged?()
            
        } catch { print("Setup error: \(error)") }
    }
    
    private func unlock(_ unlock: UnlockCharacteristic) {
        
        let keyIdentifier = unlock.identifier
        
        do {
            
            guard let (key, secret) = try authorization.key(for: keyIdentifier)
                else { print("Unknown key \(keyIdentifier)"); return }
            
            assert(key.identifier == keyIdentifier, "Invalid key")
            
            // validate HMAC
            guard unlock.authentication.isAuthenticated(with: secret)
                else { print("Invalid key secret"); return }
            
            // guard against replay attacks
            let timestamp = unlock.authentication.message.date
            let now = Date()
            guard timestamp <= now + authorizationTimeout, // cannot be used later for replay attacks
                timestamp > now - authorizationTimeout // only valid for 5 seconds
                else { print("Authentication expired \(timestamp) < \(now)"); return }
            
            // enforce schedule
            if case let .scheduled(schedule) = key.permission {
                guard schedule.isValid()
                    else { print("Cannot unlock during schedule"); return }
            }
            
            // unlock with the specified action
            try unlockDelegate.unlock(unlock.action)
            
            print("Key \(key.identifier) \(key.name) unlocked with action \(unlock.action)")
            
            try events.save(.unlock(.init(key: key.identifier, action: unlock.action)))
            
            lockChanged?()
            
        } catch { print("Unlock error: \(error)")  }
    }
    
    private func createNewKey(_ characteristic: CreateNewKeyCharacteristic) {
        
        let keyIdentifier = characteristic.identifier
        
        do {
            
            guard let (key, secret) = try authorization.key(for: keyIdentifier)
                else { print("Unknown key \(keyIdentifier)"); return }
            
            assert(key.identifier == keyIdentifier, "Invalid key")
            
            // validate HMAC
            guard characteristic.encryptedData.authentication.isAuthenticated(with: secret)
                else { print("Invalid key secret"); return }
            
            // guard against replay attacks
            let timestamp = characteristic.encryptedData.authentication.message.date
            let now = Date()
            guard timestamp <= now + authorizationTimeout, // cannot be used later for replay attacks
                timestamp > now - authorizationTimeout // only valid for 5 seconds
                else { print("Authentication expired \(timestamp) < \(now)"); return }
            
            // enforce permission
            guard key.permission.isAdministrator else {
                print("Only lock owner and admins can create new keys")
                return
            }
            
            // decrypt
            let request = try characteristic.decrypt(with: secret)
            let newKey = NewKey(request: request)
            
            try self.authorization.add(newKey, secret: request.secret)
            
            print("Key \(keyIdentifier) \(key.name) created new key \(request.identifier)")
            
            try events.save(.createNewKey(.init(key: key.identifier, newKey: newKey.identifier)))
            
            lockChanged?()
            
        } catch { print("Create new key error: \(error)")  }
    }
    
    private func confirmNewKey(_ characteristic: ConfirmNewKeyCharacteristic) {
        
        let newKeyIdentifier = characteristic.identifier
        
        do {
            
            guard let (newKey, secret) = try authorization.newKey(for: newKeyIdentifier)
                else { print("Unknown key \(newKeyIdentifier)"); return }
            
            assert(newKey.identifier == newKeyIdentifier, "Invalid key")
            
            // validate HMAC
            guard characteristic.encryptedData.authentication.isAuthenticated(with: secret)
                else { print("Invalid key secret"); return }
            
            // guard against replay attacks
            let timestamp = characteristic.encryptedData.authentication.message.date
            let now = Date()
            guard timestamp <= now + authorizationTimeout, // cannot be used later for replay attacks
                timestamp > now - authorizationTimeout // only valid for 5 seconds
                else { print("Authentication expired \(timestamp) < \(now)"); return }
            
            // decrypt
            let request = try characteristic.decrypt(with: secret)
            let keySecret = request.secret
            let key = Key(
                identifier: newKey.identifier,
                name: newKey.name,
                created: newKey.created,
                permission: newKey.permission
            )
            
            try self.authorization.removeNewKey(newKeyIdentifier)
            try self.authorization.add(key, secret: keySecret)
            
            print("Key \(newKeyIdentifier) \(key.name) confirmed with shared secret")
            
            assert(try! authorization.key(for: key.identifier) != nil, "Key not stored")
            
            try events.save(.confirmNewKey(.init(newKey: newKey.identifier, key: key.identifier)))
            
            lockChanged?()
            
        } catch { print("Confirm new key error: \(error)")  }
    }
    
    private func removeKey(_ characteristic: RemoveKeyCharacteristic) {
        
        let keyIdentifier = characteristic.identifier
        
        do {
            
            guard let (key, secret) = try authorization.key(for: keyIdentifier)
                else { print("Unknown key \(keyIdentifier)"); return }
            
            assert(key.identifier == keyIdentifier, "Invalid key")
            
            // validate HMAC
            guard characteristic.authentication.isAuthenticated(with: secret)
                else { print("Invalid key secret"); return }
            
            // guard against replay attacks
            let timestamp = characteristic.authentication.message.date
            let now = Date()
            guard timestamp <= now + authorizationTimeout, // cannot be used later for replay attacks
                timestamp > now - authorizationTimeout // only valid for 5 seconds
                else { print("Authentication expired"); return }
            
            // enforce permission
            guard key.permission.isAdministrator else {
                print("Only lock owner and admins can remove keys")
                return
            }
            
            switch characteristic.type {
            case .key:
                guard let (removeKey, _) = try authorization.key(for: characteristic.key)
                    else { print("Key \(characteristic.key) does not exist"); return }
                assert(removeKey.identifier == characteristic.key)
                try authorization.removeKey(removeKey.identifier)
            case .newKey:
                guard let (removeKey, _) = try authorization.newKey(for: characteristic.key)
                    else { print("New Key \(characteristic.key) does not exist"); return }
                assert(removeKey.identifier == characteristic.key)
                try authorization.removeNewKey(removeKey.identifier)
            }
            
            print("Key \(key.identifier) \(key.name) removed \(characteristic.type) \(characteristic.key)")
            
            try events.save(.removeKey(.init(key: key.identifier, removedKey: characteristic.key, type: characteristic.type)))
            
            lockChanged?()
            
        } catch { print("Remove key error: \(error)")  }
    }
    
    private func listKeysRequest(_ characteristic: ListKeysCharacteristic, maximumUpdateValueLength: Int) {
        
        let keyIdentifier = characteristic.identifier
        
        do {
            
            guard let (key, secret) = try authorization.key(for: keyIdentifier)
                else { print("Unknown key \(keyIdentifier)"); return }
            
            assert(key.identifier == keyIdentifier, "Invalid key")
            
            // validate HMAC
            guard characteristic.authentication.isAuthenticated(with: secret)
                else { print("Invalid key secret"); return }
            
            // guard against replay attacks
            let timestamp = characteristic.authentication.message.date
            let now = Date()
            guard timestamp <= now + authorizationTimeout, // cannot be used later for replay attacks
                timestamp > now - authorizationTimeout // only valid for 5 seconds
                else { print("Authentication expired \(timestamp) < \(now)"); return }
            
            // enforce permission
            guard key.permission.isAdministrator else {
                print("Only lock owner and admins can view list of keys")
                return
            }
            
            print("Key \(key.identifier) \(key.name) requested keys list")
            
            // send list via notifications
            let list = authorization.list
            let notifications = KeyListNotification.from(list: list)
            let notificationChunks = try notifications.map {
                ($0, try KeysCharacteristic.from($0, sharedSecret: secret, maximumUpdateValueLength: maximumUpdateValueLength))
            }
            
            // write to characteristic and issue notifications
            for (notification, chunks) in notificationChunks {
                for (index, chunk) in chunks.enumerated() {
                    peripheral[characteristic: keysResponseHandle] = chunk.data
                    print("Sent chunk \(index + 1) for \(notification.key.identifier) (\(chunk.data.count) bytes)")
                    usleep(100)
                }
            }
            
            print("Key \(key.identifier) \(key.name) recieved keys list")
            
        } catch { print("List keys error: \(error)")  }
    }
    
    private func listEventsRequest(_ characteristic: ListEventsCharacteristic, maximumUpdateValueLength: Int) {
        
        let keyIdentifier = characteristic.identifier
        
        do {
            
            guard let (key, secret) = try authorization.key(for: keyIdentifier)
                else { print("Unknown key \(keyIdentifier)"); return }
            
            assert(key.identifier == keyIdentifier, "Invalid key")
            
            // validate HMAC
            guard characteristic.authentication.isAuthenticated(with: secret)
                else { print("Invalid key secret"); return }
            
            // guard against replay attacks
            let timestamp = characteristic.authentication.message.date
            let now = Date()
            guard timestamp <= now + authorizationTimeout, // cannot be used later for replay attacks
                timestamp > now - authorizationTimeout // only valid for 5 seconds
                else { print("Authentication expired \(timestamp) < \(now)"); return }
                        
            print("Key \(key.identifier) \(key.name) requested events list")
            
            if let fetchRequest = characteristic.fetchRequest {
                dump(fetchRequest)
            }
            
            var fetchRequest = characteristic.fetchRequest ?? .init()
            
            // enforce permission, non-administrators can only view their own events.
            if key.permission.isAdministrator == false {
                var predicate = fetchRequest.predicate ?? .empty
                predicate.keys = [key.identifier]
                fetchRequest.predicate = predicate
            }
            
            // send list via notifications
            let list = try events.fetch(fetchRequest)
            let notifications = EventListNotification.from(list: list)
            let notificationChunks = try notifications.map {
                ($0, try EventsCharacteristic.from($0, sharedSecret: secret, maximumUpdateValueLength: maximumUpdateValueLength))
            }
            
            // write to characteristic and issue notifications
            for (notification, chunks) in notificationChunks {
                for (index, chunk) in chunks.enumerated() {
                    peripheral[characteristic: eventsResponseHandle] = chunk.data
                    print("Sent chunk \(index + 1)\(notification.event.flatMap({ " for event \($0.identifier)" }) ?? "") (\(chunk.data.count) bytes)")
                    usleep(100)
                }
            }
            
            print("Key \(key.identifier) \(key.name) recieved events list")
            
        } catch { print("List keys error: \(error)")  }
    }
}

/// Lock unlock manager
public protocol UnlockDelegate {
    
    func unlock(_ action: UnlockAction) throws
}

public struct UnlockSimulator: UnlockDelegate {
    
    public func unlock(_ action: UnlockAction) throws {
        
        print("Simulate unlock with action \(action)")
    }
}
