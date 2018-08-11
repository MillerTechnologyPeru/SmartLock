//
//  UnlockCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth

/// Used to unlock door.
///
/// timestamp + nonce + HMAC(key, nonce) + uuid (write-only)
public struct UnlockCharacteristic: GATTProfileCharacteristic {
    
    public static let uuid = BluetoothUUID(rawValue: "265B3EC0-044D-11E6-90F2-09AB70D5A8C7")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    internal static let length = MemoryLayout<UInt64>.size
        + Nonce.length
        + HMACSize
        + MemoryLayout<UInt128>.size
        + MemoryLayout<UnlockAction.RawValue>.size
    
    public static let properties: BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    /// Timestamp of the request
    public let date: Date
    
    /// Nonce
    public let nonce: Nonce
    
    /// HMAC of key and nonce
    public let authentication: AuthenticationData
    
    /// Identifier of key making request.
    public let identifier: UUID
    
    /// Unlock action.
    public let action: UnlockAction
    
    public init(identifier: UUID,
                action: UnlockAction = .default,
                date: Date = Date(),
                nonce: Nonce = Nonce(),
                key: KeyData) {
        
        self.identifier = identifier
        self.action = action
        self.date = date
        self.nonce = nonce
        self.authentication = HMAC(key: key, message: nonce)
    }
    
    public init?(data: Data) {
        
        guard data.count == type(of: self).length
            else { return nil }
        
        let timeInterval = UInt64(littleEndian: UInt64(bytes: (data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7])))
        
        let timestamp = Date(timeIntervalSince1970: TimeInterval(bitPattern: timeInterval))
        
        guard let nonce = Nonce(data: Data(data[8 ..< 24]))
            else { assertionFailure("Could not initialize nonce"); return nil }
        
        guard let authentication = AuthenticationData(data: Data(data[24 ..< 88]))
            else { assertionFailure("Could not initialize authentication data"); return nil }
        
        let identifier = UUID(UInt128(littleEndian: data.suffix(from: 88).withUnsafeBytes { $0.pointee }))
        
        guard let action = UnlockAction(rawValue: data[104])
            else { return nil } // invalid value
        
        self.identifier = identifier
        self.action = action
        self.date = timestamp
        self.nonce = nonce
        self.authentication = authentication
    }
    
    public var data: Data {
        
        var data = Data(capacity: type(of: self).length)
        
        data += date.timeIntervalSince1970.bitPattern.littleEndian
        data += nonce.data
        data += authentication.data
        data += UInt128(uuid: identifier).littleEndian
        data += action.rawValue
        
        assert(data.count == type(of: self).length)
        
        return data
    }
}
