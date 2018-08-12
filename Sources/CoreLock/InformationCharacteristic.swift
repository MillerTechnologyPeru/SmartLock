//
//  InformationCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth

/// Used to determine identity, compatibility and supported features.
public struct InformationCharacteristic: GATTProfileCharacteristic {
    
    public static let uuid = BluetoothUUID(rawValue: "6C728682-F57A-4255-BB4E-BFF58D1934CF")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: BitMaskOptionSet<GATT.Characteristic.Property> = [.read]
    
    internal static let length = MemoryLayout<UInt128>.size
        + MemoryLayout<UInt64>.size
        + MemoryLayout<SmartLockVersion>.size
        + MemoryLayout<Status.RawValue>.size
        + MemoryLayout<UnlockAction.RawValue>.size
    
    /// Lock identifier
    public let identifier: UUID
    
    /// Lock name
    //public let name: String
    
    /// Firmware build number
    public let buildVersion: SmartLockBuildVersion
    
    /// Firmware version
    public let version: SmartLockVersion
    
    /// Device state
    public var status: Status
    
    /// Supported lock actions
    public let unlockActions: BitMaskOptionSet<UnlockAction>
    
    public init(identifier: UUID,
                buildVersion: SmartLockBuildVersion = .current,
                version: SmartLockVersion = .current,
                status: Status,
                unlockActions: BitMaskOptionSet<UnlockAction> = []) {
        
        self.identifier = identifier
        self.buildVersion = buildVersion
        self.version = version
        self.status = status
        self.unlockActions = unlockActions
    }
    
    public init?(data: Data) {
        
        guard data.count == type(of: self).length
            else { return nil }
        
        let identifier = UUID(UInt128(littleEndian: data.subdata(in: 0 ..< 16).withUnsafeBytes { $0.pointee }))
        
        let buildVersion = UInt64(littleEndian: data.subdata(in: 16 ..< 24).withUnsafeBytes { $0.pointee })
        
        let version = SmartLockVersion(major: data[24], minor: data[25], patch: data[26])
        
        guard let status = Status(rawValue: data[27])
            else { return nil }
        
        let unlockActions = BitMaskOptionSet<UnlockAction>(rawValue: data[28])
        
        self.identifier = identifier
        self.buildVersion = SmartLockBuildVersion(rawValue: buildVersion)
        self.version = version
        self.status = status
        self.unlockActions = unlockActions
    }
    
    public var data: Data {
        
        var data = Data(capacity: type(of: self).length)
        
        data += UInt128(uuid: identifier).littleEndian
        data += buildVersion.rawValue.littleEndian
        data.append(contentsOf: [version.major, version.minor, version.patch])
        data += status.rawValue
        data += unlockActions.rawValue
        
        assert(data.count == type(of: self).length)
        
        return data
    }
}
