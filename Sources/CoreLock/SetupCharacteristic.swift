//
//  SetupCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth

public struct SetupCharacteristic {
    
    public static let uuid = BluetoothUUID(rawValue: "129E401C-044D-11E6-8FA9-09AB70D5A8C7")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    
}

/// Used for initial lock setup.
public struct SetupRequest {
    
    internal static let length = MemoryLayout<UInt128>.size + KeyData.length
    
    /// Key identifier
    public let identifier: UUID
    
    /// Key secret
    public let secret: KeyData
    
    public init?(data: Data) {
        
        guard data.count == type(of: self).length
            else { return nil }
        
        var offset = 0
        
        let identifier = UUID(UInt128(littleEndian: data[offset ..< offset + UUID.length].withUnsafeBytes { $0.pointee }))
        
        offset += UUID.length
        
        guard let secret = KeyData(data: Data(data[offset ..< offset + KeyData.length]))
            else { assertionFailure(); return nil }
        
        offset += KeyData.length
        
        self.identifier = identifier
        self.secret = secret
        
        assert(offset == type(of: self).length)
    }
    
    public var data: Data {
        
        var data = Data(capacity: type(of: self).length)
        
        data += UInt128(uuid: identifier).littleEndian
        data += secret.data
        
        assert(data.count == type(of: self).length)
        
        return data
    }
}
