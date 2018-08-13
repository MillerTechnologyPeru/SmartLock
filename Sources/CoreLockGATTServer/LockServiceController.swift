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
    
    public var lockConfiguration = LockConfiguration() {
        
        didSet { updateInformation() }
    }
    
    public var setupSecret: LockSetupSecretStore = InMemoryLockSetupSecret()
    
    public var authorization: LockAuthorizationStore = InMemoryLockAuthorization()  {
        
        didSet { updateInformation() }
    }
    
    public var unlockDelegate: LockUnlockDelegate = UnlockSimulator()
    
    public private(set) var information: InformationCharacteristic {
        
        didSet { peripheral[characteristic: informationHandle] = information.data }
    }
    
    // handles
    internal let serviceHandle: UInt16
    internal let informationHandle: UInt16
    internal let setupHandle: UInt16
    internal let unlockHandle: UInt16
    
    // MARK: - Initialization
    
    public init(peripheral: Peripheral) throws {
        
        self.peripheral = peripheral
        
        let information = InformationCharacteristic(identifier: lockConfiguration.identifier,
                                                    buildVersion: .current,
                                                    version: .current,
                                                    status: .setup,
                                                    unlockActions: [.default])
        
        let characteristics = [
            
            GATT.Characteristic(uuid: InformationCharacteristic.uuid,
                                value: information.data,
                                permissions: [.read],
                                properties: InformationCharacteristic.properties),
            
            GATT.Characteristic(uuid: SetupCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: SetupCharacteristic.properties),
            
            GATT.Characteristic(uuid: UnlockCharacteristic.uuid,
                                value: Data(),
                                permissions: [.write],
                                properties: UnlockCharacteristic.properties)
        ]
        
        self.characteristics = Set(characteristics.map { $0.uuid })
        
        let service = GATT.Service(uuid: Service.uuid,
                                   primary: Service.isPrimary,
                                   characteristics: characteristics)
        
        self.serviceHandle = try peripheral.add(service: service)
        
        self.informationHandle = peripheral.characteristics(for: InformationCharacteristic.uuid)[0]
        self.setupHandle = peripheral.characteristics(for: SetupCharacteristic.uuid)[0]
        self.unlockHandle = peripheral.characteristics(for: UnlockCharacteristic.uuid)[0]
        
        self.information = information
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
         
        default:
            
            return nil
        }
    }
    
    public func didWrite(_ write: GATTWriteConfirmation<Peripheral.Central>) {
        
        switch write.handle {
            
        case setupHandle:
            
            assert(authorization.isEmpty, "Already setup")
            
            // parse characteristic
            guard let setup = SetupCharacteristic(data: write.value)
                else { print("Could not parse \(SetupCharacteristic.self)"); return }
            
            // get key for shared device.
            let sharedSecret = setupSecret.sharedSecret
            
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
            
        case unlockHandle:
            
            assert(authorization.isEmpty == false)
            
            // parse characteristic
            guard let unlock = UnlockCharacteristic(data: write.value)
                else { print("Could not parse \(UnlockCharacteristic.self)"); return }
            
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
            
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func updateInformation() {
        
        let status: LockStatus = authorization.isEmpty ? .setup : .unlock
        
        let identifier = lockConfiguration.identifier
        
        self.information = InformationCharacteristic(identifier: identifier,
                                                     buildVersion: .current,
                                                     version: .current,
                                                     status: status,
                                                     unlockActions: [.default])
    }
}

public protocol LockSetupSecretStore {
    
    var sharedSecret: KeyData { get }
}

public struct InMemoryLockSetupSecret: LockSetupSecretStore {
    
    public let sharedSecret: KeyData
    
    public init(sharedSecret: KeyData = KeyData()) {
        
        self.sharedSecret = sharedSecret
    }
}

/// Lock Authorization Store
public protocol LockAuthorizationStore {
    
    var isEmpty: Bool { get }
    
    func add(_ key: Key, secret: KeyData) throws
    
    func key(for identifier: UUID) throws -> (key: Key, secret: KeyData)?
}

/// Lock unlock manager
public protocol LockUnlockDelegate {
    
    func unlock(_ action: UnlockAction) throws
}

public struct UnlockSimulator: LockUnlockDelegate {
    
    public func unlock(_ action: UnlockAction) throws {
        
        print("Simulate unlock with action \(action)")
    }
}

public final class InMemoryLockAuthorization: LockAuthorizationStore {
    
    public init() { }
    
    private var keys = [KeyEntry]()
    
    public var isEmpty: Bool {
        
        return keys.isEmpty
    }
    
    public func add(_ key: Key, secret: KeyData) throws {
        
        keys.append(KeyEntry(key: key, secret: secret))
    }
    
    public func key(for identifier: UUID) throws -> (key: Key, secret: KeyData)? {
        
        guard let keyEntry = keys.first(where: { $0.key.identifier == identifier })
            else { return nil }
        
        return (keyEntry.key, keyEntry.secret)
    }
}

private extension InMemoryLockAuthorization {
    
    struct KeyEntry {
        
        let key: Key
        
        let secret: KeyData
    }
}

