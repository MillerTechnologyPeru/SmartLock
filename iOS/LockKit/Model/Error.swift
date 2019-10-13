//
//  Error.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/26/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

/// Lpck app errors.
public enum LockError: Error {
    
    /// The specified lock is not in range.
    case notInRange(lock: UUID)
    
    /// No key for the specified lock.
    case noKey(lock: UUID)
    
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

#if os(iOS)
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
        
        switch self {
        case let .notInRange(lock: lock):
            userInfo[NSLocalizedDescriptionKey] = R.string.error.notInRange()
            userInfo[UserInfoKey.lock.rawValue] = lock as NSUUID
        case let .noKey(lock: lock):
            userInfo[NSLocalizedDescriptionKey] = R.string.error.noKey()
            userInfo[UserInfoKey.lock.rawValue] = lock as NSUUID
        case .invalidQRCode:
            userInfo[NSLocalizedDescriptionKey] = R.string.error.invalidQRCode()
        case .invalidNewKeyFile:
            userInfo[NSLocalizedDescriptionKey] = R.string.error.invalidNewKeyFile()
        case let .existingKey(lock: lock):
            userInfo[NSLocalizedDescriptionKey] = R.string.error.existingKey()
            userInfo[UserInfoKey.lock.rawValue] = lock as NSUUID
        case .newKeyExpired:
            userInfo[NSLocalizedDescriptionKey] = R.string.error.newKeyExpired()
        }
        
        return userInfo
    }
}
#endif
