//
//  MockScanData.swift
//  BluetoothExplorer
//
//  Created by Alsey Coleman Miller on 31/10/21.
//  Copyright © 2021 Alsey Coleman Miller. All rights reserved.
//

#if DEBUG
import Foundation
import Bluetooth
import GATT

public typealias MockScanData = ScanData<GATT.Peripheral, MockAdvertisementData>

public extension MockScanData {
    
    static let beacon = MockScanData(
        peripheral: .beacon,
        date: Date(timeIntervalSinceReferenceDate: 10_000),
        rssi: -20,
        advertisementData: .beacon,
        isConnectable: true
    )
    
    static let smartThermostat = MockScanData(
        peripheral: .smartThermostat,
        date: Date(timeIntervalSinceReferenceDate: 10_100),
        rssi: -127,
        advertisementData: .smartThermostat,
        isConnectable: true
    )
    
    static func lock(_ id: UInt8) -> MockScanData {
        MockScanData(
            peripheral: .lock(id),
            date: Date(timeIntervalSinceReferenceDate: 10_100),
            rssi: -127,
            advertisementData: .lock,
            isConnectable: true
        )
    }
    
    static var lock: MockScanData {
        .lock(0x00)
    }
}

public extension MockCentral.Peripheral {
    
    static var random: MockCentral.Peripheral {
        Peripheral(id: BluetoothAddress(bytes: (
            .random(in: .min ... .max),
            .random(in: .min ... .max),
            .random(in: .min ... .max),
            .random(in: .min ... .max),
            .random(in: .min ... .max),
            .random(in: .min ... .max)))
        )
    }
    
    static var beacon: Peripheral {
        Peripheral(id: BluetoothAddress(rawValue: "00:AA:AB:03:10:01")!)
    }
    
    static var smartThermostat: Peripheral {
        Peripheral(id: BluetoothAddress(rawValue: "00:1A:7D:DA:71:13")!)
    }
    
    static func lock(_ id: UInt8) -> Peripheral {
        Peripheral(id: .init(bigEndian: BluetoothAddress(bytes: (0x00, 0xAA, 0xBB, 0xCC, 0xDD, id))))
    }
    
    static var lock: Peripheral {
        .lock(0x00)
    }
}

public extension MockCentral.Peripheral.ID {
    
    static var random: MockCentral.Peripheral.ID {
        return MockCentral.Peripheral.random.id
    }
}

#endif
