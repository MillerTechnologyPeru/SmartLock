//
//  DeviceInformationService.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//
//

import Foundation
import Bluetooth

public struct DeviceInformationService: GATTProfileService {
    
    public static let uuid: BluetoothUUID = .deviceInformation
    
    public static let isPrimary: Bool = true
    
    public static let characteristics: [GATTProfileCharacteristic.Type] = [
        ManufacturerNameCharacteristic.self,
    ]
}

public struct ManufacturerNameCharacteristic: GATTProfileCharacteristic {
    
    public static let service: GATTProfileService.Type = DeviceInformationService.self

    public static let uuid: BluetoothUUID = .manufacturerNameString

    public let value: GATTManufacturerNameString
}
