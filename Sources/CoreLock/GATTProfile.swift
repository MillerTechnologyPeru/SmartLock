//
//  GATTProfile.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/6/18.
//

import Foundation
import Bluetooth
import GATT

/// GATT Profile
public protocol GATTProfile {
    
    static var services: [GATTProfileService.Type] { get }
}

public extension GATTProfile {
    
    static var characteristics: [GATTProfileCharacteristic.Type] {
        
        return services.reduce([]) { $0.0 + $0.1.characteristics }
    }
}

/// GATT Service
public protocol GATTProfileService {
    
    static var uuid: BluetoothUUID { get }
    
    static var isPrimary: Bool { get }
    
    static var characteristics: [GATTProfileCharacteristic.Type] { get }
}

/// GATT Service Characteristic
public protocol GATTProfileCharacteristic {
    
    static var service: GATTProfileService.Type { get }
    
    static var uuid: BluetoothUUID { get }
        
    init?(data: Data)
    
    var data: Data { get }
}
