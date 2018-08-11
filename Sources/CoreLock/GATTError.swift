//
//  Error.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/6/18.
//

import Foundation
import Bluetooth

/// Smart Lock GATT Error
public enum SmartLockGATTError: Error {
    
    /// No service with UUID found.
    case serviceNotFound(BluetoothUUID)
    
    /// No characteristic with UUID found.
    case characteristicNotFound(BluetoothUUID)
    
    /// The characteristic's value could not be parsed. Invalid data.
    case invalidCharacteristicValue(BluetoothUUID)
    
    /// Invalid data.
    case invalidData(Data?)
}

internal typealias GATTError = SmartLockGATTError

// MARK: - CustomNSError

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

extension SmartLockGATTError: CustomNSError {
    
    public enum UserInfoKey: String {
        
        /// Bluetooth UUID value (for characteristic or service).
        case uuid = "com.SmartLocksemiconductor.SmartLock.GATTError.BluetoothUUID"
        
        /// Data
        case data = "com.SmartLocksemiconductor.SmartLock.GATTError.Data"
    }
    
    /// The domain of the error.
    public static var errorDomain: String { return "com.SmartLocksemiconductor.SmartLock.GATTError" }
    
    /// The error code within the given domain.
    //public var errorCode: Int
    
    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] {
        
        var userInfo = [String : Any](minimumCapacity: 2)
        
        switch self {
            
        case let .serviceNotFound(uuid):
            
            let description = String(format: NSLocalizedString("No service with UUID %@ found.", comment: "com.SmartLocksemiconductor.SmartLock.GATTError.serviceNotFound"), uuid.description)
            
            userInfo[NSLocalizedDescriptionKey] = description
            userInfo[UserInfoKey.uuid.rawValue] = uuid
            
        case let .characteristicNotFound(uuid):
            
            let description = String(format: NSLocalizedString("No characteristic with UUID %@ found.", comment: "com.SmartLocksemiconductor.SmartLock.GATTError.characteristicNotFound"), uuid.description)
            
            userInfo[NSLocalizedDescriptionKey] = description
            userInfo[UserInfoKey.uuid.rawValue] = uuid
            
        case let .invalidCharacteristicValue(uuid):
            
            let description = String(format: NSLocalizedString("The value of characteristic %@ could not be parsed.", comment: "com.SmartLocksemiconductor.SmartLock.GATTError.invalidCharacteristicValue"), uuid.description)
            
            userInfo[NSLocalizedDescriptionKey] = description
            userInfo[UserInfoKey.uuid.rawValue] = uuid
            
        case let .invalidData(data):
            
            let description = String(format: NSLocalizedString("Invalid data.", comment: "com.SmartLocksemiconductor.SmartLock.GATTError.invalidData"))
            
            userInfo[NSLocalizedDescriptionKey] = description
            userInfo[UserInfoKey.data.rawValue] = data
        }
        
        return userInfo
    }
}

#endif
