//
//  UnlockCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth

/// Used to unlock door.
public struct UnlockCharacteristic: GATTProfileCharacteristic {
    
    public static let uuid = BluetoothUUID(rawValue: "265B3EC0-044D-11E6-90F2-09AB70D5A8C7")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    internal static let length = Authentication.length
        + MemoryLayout<UInt128>.size
        + MemoryLayout<UnlockAction.RawValue>.size
    
    public static let properties: BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    /// Identifier of key making request.
    public let identifier: UUID
    
    /// Unlock action.
    public let action: UnlockAction
    
    /// HMAC of key and nonce, and HMAC message
    public let authentication: Authentication
    
    public init(identifier: UUID,
                action: UnlockAction = .default,
                authentication: Authentication) {
        
        self.identifier = identifier
        self.action = action
        self.authentication = authentication
    }
    
    public init?(data: Data) {
        
        guard data.count == type(of: self).length
            else { return nil }
        
        var offset = 0
        
        guard let authentication = Authentication(data: data[offset ..< offset + Authentication.length])
            else { assertionFailure("Could not initialize authentication"); return nil }
        
        offset += Authentication.length
        
        let identifier = UUID(UInt128(littleEndian: data[offset ..< offset + UUID.length].withUnsafeBytes { $0.pointee }))
        
        offset += UUID.length
        
        guard let action = UnlockAction(rawValue: data[offset])
            else { return nil } // invalid value
        
        self.identifier = identifier
        self.action = action
        self.authentication = authentication
    }
    
    public var data: Data {
        
        var data = Data(capacity: type(of: self).length)
        
        data += authentication.data
        data += UInt128(uuid: identifier).littleEndian
        data += action.rawValue
        
        assert(data.count == type(of: self).length)
        
        return data
    }
}

internal struct RequestCharacteristic {
    
    enum Opcode: UInt8 {
        
        case request
        case response
        case error
    }
}
