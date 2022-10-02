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

public final class LockGATTServiceController <Peripheral: PeripheralManager> : GATTServiceController {
    
    public static var service: BluetoothUUID { return Service.uuid }
    
    public let characteristics: Set<BluetoothUUID>
    
    public typealias Service = LockService
        
    // MARK: - Properties
    
    public let peripheral: Peripheral
    
    public var configurationStore: LockConfigurationStore = InMemoryLockConfigurationStore()
        
    public var authorization: LockAuthorizationStore = InMemoryLockAuthorization()
    
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
    
    public init(peripheral: Peripheral) async throws {
        
        self.peripheral = peripheral
                
        let characteristics = [
            
            GATTAttribute.Characteristic(uuid: LockInformationCharacteristic.uuid,
                                value: Data(),
                                permissions: [.read],
                                properties: LockInformationCharacteristic.properties),
            
            GATTAttribute.Characteristic(uuid: SetupCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: SetupCharacteristic.properties),
            
            GATTAttribute.Characteristic(uuid: UnlockCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: UnlockCharacteristic.properties),
            
            GATTAttribute.Characteristic(uuid: CreateNewKeyCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: CreateNewKeyCharacteristic.properties),
            
            GATTAttribute.Characteristic(uuid: ConfirmNewKeyCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: ConfirmNewKeyCharacteristic.properties),
            
            GATTAttribute.Characteristic(uuid: RemoveKeyCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: RemoveKeyCharacteristic.properties),
            
            GATTAttribute.Characteristic(uuid: ListKeysCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: ListKeysCharacteristic.properties),
            
            GATTAttribute.Characteristic(uuid: KeysCharacteristic.uuid,
                                value: Data(),
                                permissions: [],
                                properties: KeysCharacteristic.properties,
                                descriptors: [GATTClientCharacteristicConfiguration().descriptor]),
            
            
            GATTAttribute.Characteristic(uuid: ListEventsCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: ListEventsCharacteristic.properties),
            
            GATTAttribute.Characteristic(uuid: EventsCharacteristic.uuid,
                                value: Data(),
                                permissions: [],
                                properties: EventsCharacteristic.properties,
                                descriptors: [GATTClientCharacteristicConfiguration().descriptor]),
        ]
        
        self.characteristics = Set(characteristics.map { $0.uuid })
        
        let service = GATTAttribute.Service(uuid: Service.uuid,
                                   primary: Service.isPrimary,
                                   characteristics: characteristics)
        
        self.serviceHandle = try await peripheral.add(service: service)
        
        self.informationHandle = await peripheral.characteristics(for: LockInformationCharacteristic.uuid)[0]
        self.setupHandle = await peripheral.characteristics(for: SetupCharacteristic.uuid)[0]
        self.unlockHandle = await peripheral.characteristics(for: UnlockCharacteristic.uuid)[0]
        self.createNewKeyHandle = await peripheral.characteristics(for: CreateNewKeyCharacteristic.uuid)[0]
        self.confirmNewKeyHandle = await peripheral.characteristics(for: ConfirmNewKeyCharacteristic.uuid)[0]
        self.removeKeyHandle = await peripheral.characteristics(for: RemoveKeyCharacteristic.uuid)[0]
        self.keysRequestHandle = await peripheral.characteristics(for: ListKeysCharacteristic.uuid)[0]
        self.keysResponseHandle = await peripheral.characteristics(for: KeysCharacteristic.uuid)[0]
        self.eventsRequestHandle = await peripheral.characteristics(for: ListEventsCharacteristic.uuid)[0]
        self.eventsResponseHandle = await peripheral.characteristics(for: EventsCharacteristic.uuid)[0]
        
        await updateInformation()
    }
    
    // MARK: - Methods
    
    public func reset() async {
        try? await authorization.removeAll()
        await updateInformation()
    }
    
    public func willRead(_ request: GATTReadRequest<Peripheral.Central>) -> ATTError? {
        
        switch request.handle {
        case informationHandle:
            print("Requested lock information")
            return nil
        default:
            return nil
        }
    }
    
    public func willWrite(_ request: GATTWriteRequest<Peripheral.Central>) -> ATTError? {
        
        switch request.handle {
        case setupHandle:
            //return await authorization.isEmpty ? nil : .writeNotPermitted
            return nil
        case unlockHandle:
            //return await authorization.isEmpty ? .writeNotPermitted : nil
            return nil
        case createNewKeyHandle:
            //return await authorization.isEmpty ? .writeNotPermitted : nil
            return nil
        default:
            return nil
        }
    }
    
    public func didWrite(_ write: GATTWriteConfirmation<Peripheral.Central>) async {
        
        switch write.handle {
            
        case setupHandle:
            
            //precondition(authorization.isEmpty, "Already setup")
            
            // parse characteristic
            guard let characteristic = SetupCharacteristic(data: write.value)
                else { print("Could not parse \(SetupCharacteristic.self)"); return }
            
            await setup(characteristic)
            
        case unlockHandle:
            
            //assert(authorization.isEmpty == false, "No keys")
            
            // parse characteristic
            guard let characteristic = UnlockCharacteristic(data: write.value)
                else { print("Could not parse \(UnlockCharacteristic.self)"); return }
            
            await unlock(characteristic)
            
        case createNewKeyHandle:
            
            //assert(authorization.isEmpty == false, "No keys")
            
            // parse characteristic
            guard let characteristic = CreateNewKeyCharacteristic(data: write.value)
                else { print("Could not parse \(CreateNewKeyCharacteristic.self)"); return }
            
            await createNewKey(characteristic)
            
        case confirmNewKeyHandle:
            
            //assert(authorization.isEmpty == false, "No keys")
            
            // parse characteristic
            guard let characteristic = ConfirmNewKeyCharacteristic(data: write.value)
                else { print("Could not parse \(ConfirmNewKeyCharacteristic.self)"); return }
            
            await confirmNewKey(characteristic)
            
        case removeKeyHandle:
            
            //assert(authorization.isEmpty == false, "No keys")
            
            // parse characteristic
            guard let characteristic = RemoveKeyCharacteristic(data: write.value)
                else { print("Could not parse \(RemoveKeyCharacteristic.self)"); return }
            
            await removeKey(characteristic)
            
        case keysRequestHandle:
            
            //assert(authorization.isEmpty == false, "No keys")
            
            // parse characteristic
            guard let characteristic = ListKeysCharacteristic(data: write.value)
                else { print("Could not parse \(ListKeysCharacteristic.self)"); return }
            
            await listKeysRequest(characteristic, maximumUpdateValueLength: write.maximumUpdateValueLength)
            
        case keysResponseHandle:
            assertionFailure("Not writable")
            
        case eventsRequestHandle:
            
            //assert(authorization.isEmpty == false, "Not setup yet")
            
            // parse characteristic
            guard let characteristic = ListEventsCharacteristic(data: write.value)
                else { print("Could not parse \(ListEventsCharacteristic.self)"); return }
            
            await listEventsRequest(characteristic, maximumUpdateValueLength: write.maximumUpdateValueLength)
            
        case eventsResponseHandle:
            assertionFailure("Not writable")
            
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    public func updateInformation() async {
        
        let status: LockStatus = await authorization.isEmpty ? .setup : .unlock
        let id = await configurationStore.configuration.id
        let information = LockInformationCharacteristic(
            id: id,
            buildVersion: .current,
            version: .current,
            status: status,
            unlockActions: [.default]
        )
        
        await peripheral.write(information.data, forCharacteristic: informationHandle)
    }
    
    private func setup(_ setup: SetupCharacteristic) async {
        
        guard await authorization.isEmpty else {
            return
        }
        
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
            let setupRequest = try setup.decrypt(using: sharedSecret)
            
            // create owner key
            let ownerKey = Key(setup: setupRequest)
            
            // store first key
            try await authorization.add(ownerKey, secret: setupRequest.secret)
            do {
                let isEmpty = await authorization.isEmpty
                assert(isEmpty == false)
            }
            
            print("Lock setup completed")
            
            await updateInformation()
            
            try await events.save(.setup(.init(key: ownerKey.id)))
            
            lockChanged?()
            
        } catch { print("Setup error: \(error)") }
    }
    
    private func unlock(_ characteristic: UnlockCharacteristic) async {
        
        let keyIdentifier = characteristic.encryptedData.authentication.message.id
        
        do {
            
            guard let (key, secret) = try await authorization.key(for: keyIdentifier)
                else { print("Unknown key \(keyIdentifier)"); return }
            
            assert(key.id == keyIdentifier, "Invalid key")
            
            // validate HMAC
            guard characteristic.encryptedData.authentication.isAuthenticated(using: secret)
                else { print("Invalid key secret"); return }
            
            // guard against replay attacks
            let timestamp = characteristic.encryptedData.authentication.message.date
            let now = Date()
            guard timestamp <= now + authorizationTimeout, // cannot be used later for replay attacks
                timestamp > now - authorizationTimeout // only valid for 5 seconds
                else { print("Authentication expired \(timestamp) < \(now)"); return }
            
            // enforce schedule
            if case let .scheduled(schedule) = key.permission {
                guard schedule.isValid()
                    else { print("Cannot unlock during schedule"); return }
            }
            
            let request = try characteristic.decrypt(using: secret)
            
            // unlock with the specified action
            try await unlockDelegate.unlock(request.action)
            
            print("Key \(key.id) \(key.name) unlocked with action \(request.action)")
            
            try await events.save(.unlock(.init(key: key.id, action: request.action)))
            
            lockChanged?()
            
        } catch { print("Unlock error: \(error)")  }
    }
    
    private func createNewKey(_ characteristic: CreateNewKeyCharacteristic) async {
        
        let keyIdentifier = characteristic.encryptedData.authentication.message.id
        
        do {
            
            guard let (key, secret) = try await authorization.key(for: keyIdentifier)
                else { print("Unknown key \(keyIdentifier)"); return }
            
            assert(key.id == keyIdentifier, "Invalid key")
            
            // validate HMAC
            guard characteristic.encryptedData.authentication.isAuthenticated(using: secret)
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
            let request = try characteristic.decrypt(using: secret)
            let newKey = NewKey(request: request)
            
            try await self.authorization.add(newKey, secret: request.secret)
            
            print("Key \(keyIdentifier) \(key.name) created new key \(request.id)")
            
            try await events.save(.createNewKey(.init(key: key.id, newKey: newKey.id)))
            
            lockChanged?()
            
        } catch { print("Create new key error: \(error)")  }
    }
    
    private func confirmNewKey(_ characteristic: ConfirmNewKeyCharacteristic) async {
        
        let newKeyIdentifier = characteristic.encryptedData.authentication.message.id
        
        do {
            
            guard let (newKey, secret) = try await authorization.newKey(for: newKeyIdentifier)
                else { print("Unknown key \(newKeyIdentifier)"); return }
            
            assert(newKey.id == newKeyIdentifier, "Invalid key")
            
            // validate HMAC
            guard characteristic.encryptedData.authentication.isAuthenticated(using: secret)
                else { print("Invalid key secret"); return }
            
            // guard against replay attacks
            let timestamp = characteristic.encryptedData.authentication.message.date
            let now = Date()
            guard timestamp <= now + authorizationTimeout, // cannot be used later for replay attacks
                timestamp > now - authorizationTimeout // only valid for 5 seconds
                else { print("Authentication expired \(timestamp) < \(now)"); return }
            
            // decrypt
            let request = try characteristic.decrypt(using: secret)
            let keySecret = request.secret
            let key = Key(
                id: newKey.id,
                name: newKey.name,
                created: newKey.created,
                permission: newKey.permission
            )
            
            try await self.authorization.removeNewKey(newKeyIdentifier)
            try await self.authorization.add(key, secret: keySecret)
            
            print("Key \(newKeyIdentifier) \(key.name) confirmed with shared secret")
            
            //assert(try! authorization.key(for: key.id) != nil, "Key not stored")
            
            try await events.save(.confirmNewKey(.init(newKey: newKey.id, key: key.id)))
            
            lockChanged?()
            
        } catch { print("Confirm new key error: \(error)")  }
    }
    
    private func removeKey(_ characteristic: RemoveKeyCharacteristic) async {
        
        let keyIdentifier = characteristic.encryptedData.authentication.message.id
        
        do {
            
            guard let (key, secret) = try await authorization.key(for: keyIdentifier)
                else { print("Unknown key \(keyIdentifier)"); return }
            
            assert(key.id == keyIdentifier, "Invalid key")
            
            // validate HMAC
            guard characteristic.encryptedData.authentication.isAuthenticated(using: secret)
                else { print("Invalid key secret"); return }
            
            // guard against replay attacks
            let timestamp = characteristic.encryptedData.authentication.message.date
            let now = Date()
            guard timestamp <= now + authorizationTimeout, // cannot be used later for replay attacks
                timestamp > now - authorizationTimeout // only valid for 5 seconds
                else { print("Authentication expired"); return }
            
            // enforce permission
            guard key.permission.isAdministrator else {
                print("Only lock owner and admins can remove keys")
                return
            }
            
            // decrypt
            let request = try characteristic.decrypt(using: secret)
            
            switch request.type {
            case .key:
                guard let (removeKey, _) = try await authorization.key(for: request.id)
                    else { print("Key \(request.id) does not exist"); return }
                assert(removeKey.id == request.id)
                try await authorization.removeKey(removeKey.id)
            case .newKey:
                guard let (removeKey, _) = try await authorization.newKey(for: request.id)
                    else { print("New Key \(request.id) does not exist"); return }
                assert(removeKey.id == request.id)
                try await authorization.removeNewKey(removeKey.id)
            }
            
            print("Key \(key.id) \(key.name) removed \(request.type) \(request.id)")
            
            try await events.save(.removeKey(.init(key: key.id, removedKey: request.id, type: request.type)))
            
            lockChanged?()
            
        } catch { print("Remove key error: \(error)")  }
    }
    
    private func listKeysRequest(_ characteristic: ListKeysCharacteristic, maximumUpdateValueLength: Int) async {
        
        let keyIdentifier = characteristic.authentication.message.id
        
        do {
            
            guard let (key, secret) = try await authorization.key(for: keyIdentifier)
                else { print("Unknown key \(keyIdentifier)"); return }
            
            assert(key.id == keyIdentifier, "Invalid key")
            
            // validate HMAC
            guard characteristic.authentication.isAuthenticated(using: secret)
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
            
            print("Key \(key.id) \(key.name) requested keys list")
            
            // send list via notifications
            let list = await authorization.list
            let notifications = KeyListNotification.from(list: list)
            let notificationChunks = try notifications.map {
                ($0, try KeysCharacteristic.from($0, id: key.id, key: secret, maximumUpdateValueLength: maximumUpdateValueLength))
            }
            
            // write to characteristic and issue notifications
            for (notification, chunks) in notificationChunks {
                for (index, chunk) in chunks.enumerated() {
                    await peripheral.write(chunk.data, forCharacteristic: keysResponseHandle)
                    print("Sent chunk \(index + 1) for \(notification.key.id) (\(chunk.data.count) bytes)")
                    try await Task.sleep(nanoseconds: 10_000_000)
                }
            }
            
            print("Key \(key.id) \(key.name) recieved keys list")
            
        } catch { print("List keys error: \(error)")  }
    }
    
    private func listEventsRequest(_ characteristic: ListEventsCharacteristic, maximumUpdateValueLength: Int) async {
        
        let keyIdentifier = characteristic.encryptedData.authentication.message.id
        
        do {
            
            guard let (key, secret) = try await authorization.key(for: keyIdentifier)
                else { print("Unknown key \(keyIdentifier)"); return }
            
            assert(key.id == keyIdentifier, "Invalid key")
            
            // validate HMAC
            guard characteristic.encryptedData.authentication.isAuthenticated(using: secret)
                else { print("Invalid key secret"); return }
            
            // guard against replay attacks
            let timestamp = characteristic.encryptedData.authentication.message.date
            let now = Date()
            guard timestamp <= now + authorizationTimeout, // cannot be used later for replay attacks
                timestamp > now - authorizationTimeout // only valid for 5 seconds
                else { print("Authentication expired \(timestamp) < \(now)"); return }
                        
            print("Key \(key.id) \(key.name) requested events list")
            
            // decrypt
            let request = try characteristic.decrypt(using: secret)
            
            if let fetchRequest = request.fetchRequest {
                dump(fetchRequest)
            }
            
            var fetchRequest = request.fetchRequest ?? .init()
            
            // enforce permission, non-administrators can only view their own events.
            if key.permission.isAdministrator == false {
                var predicate = fetchRequest.predicate ?? .empty
                predicate.keys = [key.id]
                fetchRequest.predicate = predicate
            }
            
            // send list via notifications
            let list = try await events.fetch(fetchRequest)
            let notifications = EventListNotification.from(list: list)
            let notificationChunks = try notifications.map {
                ($0, try EventsCharacteristic.from($0, id: key.id, key: secret, maximumUpdateValueLength: maximumUpdateValueLength))
            }
            
            // write to characteristic and issue notifications
            for (notification, chunks) in notificationChunks {
                for (index, chunk) in chunks.enumerated() {
                    await peripheral.write(chunk.data, forCharacteristic: eventsResponseHandle)
                    print("Sent chunk \(index + 1)\(notification.event.flatMap({ " for event \($0.id)" }) ?? "") (\(chunk.data.count) bytes)")
                    try await Task.sleep(nanoseconds: 10_000_000)
                }
            }
            
            print("Key \(key.id) \(key.name) recieved events list")
            
        } catch { print("List keys error: \(error)")  }
    }
}

/// Lock unlock manager
public protocol UnlockDelegate: AnyObject {
    
    func unlock(_ action: UnlockAction) async throws
}

public actor UnlockSimulator: UnlockDelegate {
    
    public private(set) var count: Int = 0
    
    public func unlock(_ action: UnlockAction) {
        count += 1
        print("Simulate unlock \(count) with action \(action)")
    }
}
