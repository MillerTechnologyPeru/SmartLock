//
//  AuthenticationError.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

public enum LockAuthenticationError: Error {
    
    /// Invalid authentication HMAC signature.
    case invalidAuthentication
    
    /// Could not decrypt value.
    case decryptionError(Error)
    
    /// Could not encrypt value.
    case encryptionError(Error)
}

internal typealias AuthenticationError = LockAuthenticationError
