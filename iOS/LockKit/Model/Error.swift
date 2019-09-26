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
            userInfo[NSLocalizedDescriptionKey] = R.string.localizable.errorNotInRange()
            userInfo[UserInfoKey.lock.rawValue] = lock as NSUUID
        case let .noKey(lock: lock):
            userInfo[NSLocalizedDescriptionKey] = R.string.localizable.errorNoKey()
            userInfo[UserInfoKey.lock.rawValue] = lock as NSUUID
        }
        
        return userInfo
    }
}
#endif
