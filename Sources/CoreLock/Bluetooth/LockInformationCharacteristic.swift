//
//  InformationCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import GATT

/// Used to determine identity, compatibility and supported features.
public struct LockInformationCharacteristic: TLVCharacteristic, Equatable, Codable {
    
    public static let uuid = BluetoothUUID(rawValue: "6C728682-F57A-4255-BB4E-BFF58D1934CF")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.read]
    
    /// Lock identifier
    public let id: UUID
    
    /// Firmware build number
    public let buildVersion: LockBuildVersion
    
    /// Firmware version
    public let version: LockVersion
    
    /// Device state
    public var status: LockStatus
    
    /// Supported lock actions
    public let unlockActions: BitMaskOptionSet<UnlockAction>
    
    public init(id: UUID,
                buildVersion: LockBuildVersion = .current,
                version: LockVersion = .current,
                status: LockStatus,
                unlockActions: BitMaskOptionSet<UnlockAction> = [.default]) {
        
        self.id = id
        self.buildVersion = buildVersion
        self.version = version
        self.status = status
        self.unlockActions = unlockActions
    }
}
