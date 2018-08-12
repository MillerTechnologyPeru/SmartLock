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
    
    public typealias Service = LockService
    
    public static var service: GATTProfileService.Type { return Service.self }
    
    // MARK: - Properties
    
    public let peripheral: Peripheral
    
    public var information: InformationCharacteristic {
        
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
        
        return nil
    }
    
    public func didWrite(_ write: GATTWriteConfirmation<Peripheral.Central>) {
        
        
    }
}
