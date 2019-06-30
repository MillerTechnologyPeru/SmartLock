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

public final class LockServiceController <Peripheral: PeripheralProtocol> : GATTServiceController {
    
    public static var service: BluetoothUUID { return Service.uuid }
    
    public let characteristics: Set<BluetoothUUID>
    
    public typealias Service = LockService
        
    // MARK: - Properties
    
    public let peripheral: Peripheral
    
    public var hardware: LockHardware = .empty  {
        
        didSet { updateInformation() }
    }
    
    public var configurationStore: LockConfigurationStore {
        
        didSet { updateInformation() }
    }
    
    // data source / delegate
    
    public var setupSecret: KeyData = KeyData()
    
    public var authorization: LockAuthorizationStore = InMemoryLockAuthorization()  {
        
        didSet { updateInformation() }
    }
    
    public var unlockDelegate: UnlockDelegate = UnlockSimulator()
    
    // handles
    internal let serviceHandle: UInt16
    internal let informationHandle: UInt16
    internal let setupHandle: UInt16
    internal let unlockHandle: UInt16
    internal let createNewKeyHandle: UInt16
    internal let confirmNewKeyHandle: UInt16
    internal let keysRequestHandle: UInt16
    internal let keysResponseHandle: UInt16
    internal let removeKeyHandle: UInt16
    
    // MARK: - Initialization
    
    public init(peripheral: Peripheral) throws {
        
        self.peripheral = peripheral
        
        let configurationStore = InMemoryLockConfigurationStore()
        
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
            
            GATT.Characteristic(uuid: ListKeysCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: ListKeysCharacteristic.properties),
            
            GATT.Characteristic(uuid: KeysCharacteristic.uuid,
                                value: Data(),
                                permissions: [],
                                properties: KeysCharacteristic.properties),
            
            GATT.Characteristic(uuid: RemoveKeyCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: RemoveKeyCharacteristic.properties),
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
        self.keysRequestHandle = peripheral.characteristics(for: ListKeysCharacteristic.uuid)[0]
        self.keysResponseHandle = peripheral.characteristics(for: KeysCharacteristic.uuid)[0]
        self.removeKeyHandle = peripheral.characteristics(for: RemoveKeyCharacteristic.uuid)[0]
        
        self.configurationStore = configurationStore
        
        updateInformation()
    }
    
    deinit {
        
        self.peripheral.remove(service: serviceHandle)
    }
    
    // MARK: - Methods
    
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
            
        case keysRequestHandle:
            
            assert(authorization.isEmpty == false, "No keys")
            
            // parse characteristic
            guard let characteristic = ListKeysCharacteristic(data: write.value)
                else { print("Could not parse \(ListKeysCharacteristic.self)"); return }
            
        case keysResponseHandle:
            
            assertionFailure("Not writable")
            
        case removeKeyHandle:
            
            assert(authorization.isEmpty == false, "No keys")
            
            // parse characteristic
            guard let characteristic = RemoveKeyCharacteristic(data: write.value)
                else { print("Could not parse \(RemoveKeyCharacteristic.self)"); return }
            
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
        
        // get key for shared device.
        let sharedSecret = setupSecret
        
        do {
            
            // guard against replay attacks
            let timestamp = setup.encryptedData.authentication.message.date
            let now = Date()
            guard timestamp < now, // cannot be used later for replay attacks
                timestamp > now - 5.0 // only valid for 5 seconds
                else { print("Authentication expired"); return }
            
            // decrypt request
            let setupRequest = try setup.decrypt(with: sharedSecret)
            
            // create owner key
            let ownerKey = Key(setup: setupRequest)
            
            // store first key
            try authorization.add(ownerKey, secret: setupRequest.secret)
            
            print("Lock setup completed")
            
            updateInformation()
            
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
            guard timestamp < now, // cannot be used later for replay attacks
                timestamp > now - 5.0 // only valid for 5 seconds
                else { print("Authentication expired"); return }
            
            // enforce schedule
            if case let .scheduled(schedule) = key.permission {
                
                guard schedule.isValid()
                    else { print("Cannot unlock during schedule"); return }
            }
            
            // unlock with the specified action
            try unlockDelegate.unlock(unlock.action)
            
            print("Key \(key.identifier) \(key.name) unlocked with action \(unlock.action)")
            
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
            guard timestamp < now, // cannot be used later for replay attacks
                timestamp > now - 5.0 // only valid for 5 seconds
                else { print("Authentication expired"); return }
            
            // decrypt
            let request = try characteristic.decrypt(with: secret)
            let newKey = NewKey(request: request)
            
            try self.authorization.add(newKey, secret: request.secret)
            
            print("Key \(keyIdentifier) created new key \(request.identifier)")
            
        } catch { print("Create new key error: \(error)")  }
    }
}

/// Lock Configuration Storage
public protocol LockConfigurationStore {
    
    var configuration: LockConfiguration { get }
    
    func update(_ configuration: LockConfiguration) throws
}

/// Lock Authorization Store
public protocol LockAuthorizationStore {
    
    var isEmpty: Bool { get }
    
    func add(_ key: Key, secret: KeyData) throws
    
    func key(for identifier: UUID) throws -> (key: Key, secret: KeyData)?
    
    func add(_ key: NewKey, secret: KeyData) throws
    
    func newKey(for identifier: UUID) throws -> (newKey: NewKey, secret: KeyData)?
    
    var list: KeysList { get }
}

/// Lock unlock manager
public protocol UnlockDelegate {
    
    func unlock(_ action: UnlockAction) throws
}

public final class InMemoryLockConfigurationStore: LockConfigurationStore {
    
    public private(set) var configuration: LockConfiguration
    
    public init(configuration: LockConfiguration = LockConfiguration()) {
        
        self.configuration = configuration
    }
    
    public func update(_ configuration: LockConfiguration) throws {
        
        self.configuration = configuration
    }
}

public struct UnlockSimulator: UnlockDelegate {
    
    public func unlock(_ action: UnlockAction) throws {
        
        print("Simulate unlock with action \(action)")
    }
}

public final class InMemoryLockAuthorization: LockAuthorizationStore {
    
    public init() { }
    
    private var keys = [KeyEntry]()
    
    private var newKeys = [NewKeyEntry]()
    
    public var isEmpty: Bool {
        
        return keys.isEmpty && newKeys.isEmpty
    }
    
    public func add(_ key: Key, secret: KeyData) throws {
        
        keys.append(KeyEntry(key: key, secret: secret))
    }
    
    public func key(for identifier: UUID) throws -> (key: Key, secret: KeyData)? {
        
        guard let keyEntry = keys.first(where: { $0.key.identifier == identifier })
            else { return nil }
        
        return (keyEntry.key, keyEntry.secret)
    }
    
    public func add(_ key: NewKey, secret: KeyData) throws {
        
        newKeys.append(NewKeyEntry(newKey: key, secret: secret))
    }
    
    public func newKey(for identifier: UUID) throws -> (newKey: NewKey, secret: KeyData)? {
        
        guard let keyEntry = newKeys.first(where: { $0.newKey.identifier == identifier })
            else { return nil }
        
        return (keyEntry.newKey, keyEntry.secret)
    }
    
    public var list: KeysList {
        
        return KeysList(
            keys: keys.map { $0.key },
            newKeys: newKeys.map { $0.newKey }
        )
    }
}

private extension InMemoryLockAuthorization {
    
    struct KeyEntry {
        
        let key: Key
        
        let secret: KeyData
    }
    
    struct NewKeyEntry {
        
        let newKey: NewKey
        
        let secret: KeyData
    }
}
