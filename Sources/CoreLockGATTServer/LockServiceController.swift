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
    
    public var authorization: LockAuthorizationDataSource = InMemoryLockAuthorization()
    
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
        
        let information = InformationCharacteristic(identifier: UUID(),
                                                    buildVersion: .current,
                                                    version: .current,
                                                    status: .setup,
                                                    unlockActions: [])
        
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
            
            return authorization.canSetup ? nil : .writeNotPermitted
            
        case unlockHandle:
            
            return authorization.canSetup ? .writeNotPermitted : nil
         
        default:
            
            return nil
        }
    }
    
    public func didWrite(_ write: GATTWriteConfirmation<Peripheral.Central>) {
        
        switch write.handle {
            
        case setupHandle:
            
            assert(authorization.canSetup)
            
            // parse characteristic
            guard let setup = SetupCharacteristic(data: write.value)
                else { print("Could not parse \(SetupCharacteristic.self)"); return }
            
            // get key for shared device.
            let sharedSecret = authorization.sharedSecret
            
            do {
                
                // decrypt request
                let setupRequest = try setup.decrypt(with: sharedSecret)
                
                // create owner key
                try authorization.setup(setupRequest) // should not fail
                
                print("Lock setup completed")
                
            } catch { print("Setup error: \(error)") }
            
        case unlockHandle:
            
            assert(authorization.canSetup == false)
            
            // parse characteristic
            guard let unlock = UnlockCharacteristic(data: write.value)
                else { print("Could not parse \(UnlockCharacteristic.self)"); return }
            
            let keyIdentifier = unlock.identifier
            
            do {
                
                guard let (key, secret) = try authorization.key(for: keyIdentifier)
                    else { print("Unknown key \(keyIdentifier)"); return }
                
                assert(key.identifier == keyIdentifier, "Invalid key")
                
                guard unlock.authentication.isAuthenticated(with: secret)
                    else { print("Invalid key secret"); return }
                
                // unlock with the specified action
                try unlockDelegate.unlock(unlock.action)
                
                print("Key \(key.identifier) unlocked with action \(unlock)")
                
            } catch { print("Unlock error: \(error)")  }
            
        default:
            break
        }
    }
}

/// Lock Authorization delegate
public protocol LockAuthorizationDataSource {
    
    var sharedSecret: KeyData { get }
    
    var canSetup: Bool { get }
    
    func setup(_ request: SetupRequest) throws
    
    func key(for identifier: UUID) throws -> (key: Key, secret: KeyData)?
}

/// Lock unlock manager
public protocol LockUnlockDelegate {
    
    func unlock(_ action: UnlockAction) throws
}

public struct UnlockSimulator: LockUnlockDelegate {
    
    public func unlock(_ action: UnlockAction) throws {
        
        print("Did unlock with action \(action)")
    }
}

public final class InMemoryLockAuthorization: LockAuthorizationDataSource {
    
    public init(sharedSecret: KeyData = KeyData()) {
        
        self.sharedSecret = sharedSecret
        
        print("Shared secret:", sharedSecret.data.base64EncodedString())
    }
    
    public var sharedSecret: KeyData
    
    public private(set) var keys = [KeyEntry]()
    
    public var canSetup: Bool {
        
        return keys.isEmpty
    }
    
    public func setup(_ request: SetupRequest) throws {
        
        assert(canSetup, "Already setup")
        
        let ownerKey = Key(identifier: request.identifier,
                      name: "Owner",
                      permission: .owner)
        
        keys.append(KeyEntry(key: ownerKey, secret: request.secret))
    }
    
    public func key(for identifier: UUID) throws -> (key: Key, secret: KeyData)? {
        
        guard let keyEntry = keys.first(where: { $0.key.identifier == identifier })
            else { return nil }
        
        return (keyEntry.key, keyEntry.secret)
    }
}

public extension InMemoryLockAuthorization {
    
    public struct KeyEntry {
        
        public let key: Key
        
        public let secret: KeyData
    }
}

