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
    
    /// Invalid data.
    case invalidData(Data?)
    
    /// Could not complete GATT operation. 
    case couldNotComplete
}

internal typealias GATTError = SmartLockGATTError

/*
// MARK: - CustomNSError

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

extension SmartLockGATTError: CustomNSError {
    
    public enum UserInfoKey: String {
        
        /// Bluetooth UUID value (for characteristic or service).
        case uuid = "com.colemancda.CoreLock.GATTError.BluetoothUUID"
        
        /// Data
        case data = "com.colemancda.CoreLock.GATTError.Data"
    }
    
    /// The domain of the error.
    public static var errorDomain: String { return "com.colemancda.CoreLock.GATTError" }
    
    /// The error code within the given domain.
    //public var errorCode: Int
    
    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] {
        
        var userInfo = [String : Any](minimumCapacity: 2)
        
        switch self {
            
        case let .serviceNotFound(uuid):
            
            let description = String(format: NSLocalizedString("No service with UUID %@ found.", comment: "com.colemancda.CoreLock.GATTError.serviceNotFound"), uuid.description)
            
            userInfo[NSLocalizedDescriptionKey] = description
            userInfo[UserInfoKey.uuid.rawValue] = uuid
            
        case let .characteristicNotFound(uuid):
            
            let description = String(format: NSLocalizedString("No characteristic with UUID %@ found.", comment: "com.colemancda.CoreLock.GATTError.characteristicNotFound"), uuid.description)
            
            userInfo[NSLocalizedDescriptionKey] = description
            userInfo[UserInfoKey.uuid.rawValue] = uuid
            
        case let .invalidCharacteristicValue(uuid):
            
            let description = String(format: NSLocalizedString("The value of characteristic %@ could not be parsed.", comment: "com.colemancda.CoreLock.GATTError.invalidCharacteristicValue"), uuid.description)
            
            userInfo[NSLocalizedDescriptionKey] = description
            userInfo[UserInfoKey.uuid.rawValue] = uuid
            
        case let .invalidData(data):
            
            let description = String(format: NSLocalizedString("Invalid data.", comment: "com.colemancda.CoreLock.GATTError.invalidData"))
            
            userInfo[NSLocalizedDescriptionKey] = description
            userInfo[UserInfoKey.data.rawValue] = data
        }
        
        return userInfo
    }
}

#endif
*/
