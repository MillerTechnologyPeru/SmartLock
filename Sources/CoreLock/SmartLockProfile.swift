//
//  SmartLockProfile.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth
import GATT

public struct LockService: GATTProfileService {
    
    public static let uuid = BluetoothUUID(rawValue: "E47D83A9-1366-432A-A5C6-734BA62FAF7E")!
    
    public static let isPrimary: Bool = true
    
    public static let characteristics: [GATTProfileCharacteristic.Type] = [
        InformationCharacteristic.self,
        UnlockCharacteristic.self,
        SetupCharacteristic.self
    ]
}

