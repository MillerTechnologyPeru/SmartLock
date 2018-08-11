//
//  SetupCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth

/// Used for initial lock setup.
///
/// timestamp + nonce + HMAC(salt, nonce) + IV +
public struct SetupRequest {
    
    /// Timestamp of the request
    public let date: Date
    
    /// Nonce
    public let nonce: Nonce
    
    /// HMAC of secret and nonce
    public let authentication: AuthenticationData
    
    /// Crypto IV
    public let initializationVector: InitializationVector
    
    /// Encrypted data
    public let encryptedData: Data
}
