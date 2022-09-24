//
//  Error.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/26/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

/// Lock app errors.
public enum LockError: Error {
    
    case bluetoothUnavailable
    
    case unknownLock(NativePeripheral)
    
    /// The specified lock is not in range.
    case notInRange(lock: UUID)
    
    /// No key for the specified lock.
    case noKey(lock: UUID)
    
    /// Must be an administrator for the specified lock.
    case notAdmin(lock: UUID)
    
    /// Invalid QR code.
    case invalidQRCode
    
    /// Invalid new key file.
    case invalidNewKeyFile
    
    /// You already have a key for this lock.
    case existingKey(lock: UUID)
    
    /// New key expired.
    case newKeyExpired
}


// MARK: - CustomNSError

extension LockError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .unknownLock:
            return "Unable to read lock information"
        case let .notInRange(lock: lock):
            return "Lock \(lock) Not in range" //R.string.error.notInRange()
        case let .noKey(lock: lock):
            return "No key for lock \(lock)" //R.string.error.noKey()
        case let .notAdmin(lock: lock):
            return "Not an admin of lock \(lock)" //R.string.error.notAdmin()
        case .invalidQRCode:
            return "Invalid QR code" //R.string.error.invalidQRCode()
        case .invalidNewKeyFile:
            return "Invalid key invitation" //R.string.error.invalidNewKeyFile()
        case let .existingKey(lock: lock):
            return "You already have an existing key for lock \(lock)" //R.string.error.existingKey()
        case .newKeyExpired:
            return "Key invitation expired" //R.string.error.newKeyExpired()
        case .bluetoothUnavailable:
            return "Bluetooth unavailable"
        }
    }
}

extension LockError: CustomNSError {
    
    public enum UserInfoKey: String {
        
        /// Lock identifier
        case lock = "com.colemancda.LockKit.LockError.lock"
    }
    
    /// The domain of the error.
    public static var errorDomain: String { return "com.colemancda.LockKit.LockError" }
    
    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] {
        
        var userInfo = [String : Any](minimumCapacity: 2)
        userInfo[NSLocalizedDescriptionKey] = self.errorDescription
        
        switch self {
        case let .notInRange(lock: lock):
            userInfo[UserInfoKey.lock.rawValue] = lock as NSUUID
        case let .noKey(lock: lock):
            userInfo[UserInfoKey.lock.rawValue] = lock as NSUUID
        case let .notAdmin(lock: lock):
            userInfo[UserInfoKey.lock.rawValue] = lock as NSUUID
        case .invalidQRCode:
            break
        case .invalidNewKeyFile:
            break
        case let .existingKey(lock: lock):
            userInfo[UserInfoKey.lock.rawValue] = lock as NSUUID
        case .newKeyExpired:
            break
        case .bluetoothUnavailable:
            break
        case .unknownLock:
            break
        }
        
        return userInfo
    }
}
