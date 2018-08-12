//
//  Crypto.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 4/17/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import CryptoSwift

/// Generate random data with the specified size.
internal func random(_ size: Int) -> Data {
    
    let bytes = AES.randomIV(size)
    
    return Data(bytes: bytes)
}

internal let HMACSize = 64

/// Performs HMAC with the specified key and message.
@inline(__always)
internal func HMAC(key: KeyData, message: AuthenticationMessage) -> AuthenticationData {
    
    let hmac = try! CryptoSwift.HMAC(key: key.data.bytes, variant: .sha512).authenticate(message.data.bytes)
    
    assert(hmac.count == HMACSize)
    
    return AuthenticationData(data: Data(bytes: hmac))!
}

internal let IVSize = AES.blockSize

/// Encrypt data
internal func encrypt(key: Data, data: Data) -> (encrypted: Data, iv: InitializationVector) {
    
    let iv = InitializationVector()
    
    let crypto = try! AES(key: key.bytes, iv: iv.data.bytes)
    
    let byteValue = try! crypto.encrypt(data.bytes)
    
    return (Data(bytes: byteValue), iv)
}

/// Decrypt data
internal func decrypt(key: Data, iv: InitializationVector, data: Data) -> Data {
    
    assert(iv.data.count == IVSize)
    
    let crypto = try! AES(key: key.bytes, iv: iv.data.bytes)
    
    let byteValue = try! crypto.decrypt(data.bytes)
    
    return Data(bytes: byteValue)
}
