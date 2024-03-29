//
//  MockService.swift
//  
//
//  Created by Alsey Coleman Miller on 18/12/21.
//

#if DEBUG
import Foundation
import SwiftUI
import Bluetooth
import GATT
import CoreLock

typealias MockService = GATT.Service<GATT.Peripheral, UInt16>
typealias MockCharacteristic = GATT.Characteristic<GATT.Peripheral, UInt16>
typealias MockDescriptor = GATT.Descriptor<GATT.Peripheral, UInt16>

extension MockService {
    
    static var deviceInformation: MockService {
        Service(
            id: 10,
            uuid: .deviceInformation,
            peripheral: .beacon
        )
    }
    
    static var battery: MockService {
        Service(
            id: 20,
            uuid: .batteryService,
            peripheral: .beacon
        )
    }
    
    static var savantSystems: MockService {
        Service(
            id: 30,
            uuid: .savantSystems2,
            peripheral: .smartThermostat
        )
    }
    
    static func lock(_ id: UInt8) -> MockService {
        Service(
            id: 40,
            uuid: LockService.uuid,
            peripheral: .lock(id)
        )
    }
}

extension MockCharacteristic {
    
    static var deviceName: MockCharacteristic {
        Characteristic(
            id: 11,
            uuid: .deviceName,
            peripheral: .beacon,
            properties: [.read]
        )
    }
    
    static var manufacturerName: MockCharacteristic {
        Characteristic(
            id: 12,
            uuid: .manufacturerNameString,
            peripheral: .beacon,
            properties: [.read]
        )
    }
    
    static var modelNumber: MockCharacteristic {
        Characteristic(
            id: 13,
            uuid: .modelNumberString,
            peripheral: .beacon,
            properties: [.read]
        )
    }
    
    static var serialNumber: MockCharacteristic {
        Characteristic(
            id: 14,
            uuid: .serialNumberString,
            peripheral: .beacon,
            properties: [.read]
        )
    }
    
    static var batteryLevel: MockCharacteristic {
        Characteristic(
            id: 21,
            uuid: .batteryLevel,
            peripheral: .beacon,
            properties: [.read, .notify]
        )
    }
    
    static let savantTest: MockCharacteristic = Characteristic(
        id: 31,
        uuid: BluetoothUUID(),
        peripheral: .smartThermostat,
        properties: [.read, .write, .writeWithoutResponse, .notify]
    )
    
    static func lockInformation(_ id: UInt8) -> MockCharacteristic {
        Characteristic(
            id: 41,
            uuid: LockInformationCharacteristic.uuid,
            peripheral: .lock(id),
            properties: LockInformationCharacteristic.properties
        )
    }
    
    static func unlock(_ id: UInt8) -> MockCharacteristic {
        Characteristic(
            id: 42,
            uuid: UnlockCharacteristic.uuid,
            peripheral: .lock(id),
            properties: UnlockCharacteristic.properties
        )
    }
    
    static func lockEventsRequest(_ id: UInt8) -> MockCharacteristic {
        Characteristic(
            id: 43,
            uuid: ListEventsCharacteristic.uuid,
            peripheral: .lock(id),
            properties: ListEventsCharacteristic.properties
        )
    }
    
    static func lockEventsNotifications(_ id: UInt8) -> MockCharacteristic {
        Characteristic(
            id: 44,
            uuid: EventsCharacteristic.uuid,
            peripheral: .lock(id),
            properties: EventsCharacteristic.properties
        )
    }
    
    static func lockKeysRequest(_ id: UInt8) -> MockCharacteristic {
        Characteristic(
            id: 45,
            uuid: ListKeysCharacteristic.uuid,
            peripheral: .lock(id),
            properties: ListKeysCharacteristic.properties
        )
    }
    
    static func lockKeysNotifications(_ id: UInt8) -> MockCharacteristic {
        Characteristic(
            id: 46,
            uuid: KeysCharacteristic.uuid,
            peripheral: .lock(id),
            properties: KeysCharacteristic.properties
        )
    }
}

extension MockDescriptor {
    
    static func clientCharacteristicConfiguration(_ peripheral: Peripheral) -> MockDescriptor {
        Descriptor(
            id: 99,
            uuid: .clientCharacteristicConfiguration,
            peripheral: peripheral
        )
    }
}

#endif
