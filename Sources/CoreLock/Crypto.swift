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
    
    return Data(bytes)
}

internal let HMACSize = 64

/// Performs HMAC with the specified key and message.
@inline(__always)
internal func HMAC(key: KeyData, message: AuthenticationMessage) -> AuthenticationData {
    
    let hmac = try! CryptoSwift.HMAC(key: key.data.bytes, variant: .sha512).authenticate(message.data.bytes)
    
    assert(hmac.count == HMACSize)
    
    return AuthenticationData(data: Data(hmac))!
}

internal let IVSize = AES.blockSize

/// Encrypt data
internal func encrypt(key: Data, data: Data) throws -> (encrypted: Data, iv: InitializationVector) {
    
    let iv = InitializationVector()
    let crypto = try AES(key: key, iv: iv)
    let encryptedData = try crypto.encrypt(data.bytes)
    return (Data(encryptedData), iv)
}

/// Decrypt data
internal func decrypt(key: Data, iv: InitializationVector, data: Data) throws -> Data {
    
    assert(iv.data.count == IVSize)
    
    let crypto = try AES(key: key, iv: iv)
    let byteValue = try crypto.decrypt(data.bytes)
    return Data(byteValue)
}

internal extension AES {
    
    convenience init(key: Data, iv: InitializationVector) throws {
        try self.init(key: Array(key), blockMode: CBC(iv: Array(iv.data)), padding: .pkcs7)
    }
}
