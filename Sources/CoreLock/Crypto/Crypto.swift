//
//  Crypto.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 4/17/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import TLVCoding
#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#endif

#if canImport(CryptoKit)
typealias HMAC = CryptoKit.HMAC
#elseif canImport(Crypto)
typealias HMAC = Crypto.HMAC
#endif

/// Performs HMAC with the specified key and message.
internal func authenticationCode(for message: AuthenticationMessage, using key: KeyData) -> AuthenticationData {
    let encoder = TLVEncoder.lock
    let messageData = try! encoder.encode(message)
    let authenticationCode = HMAC<SHA512>.authenticationCode(for: messageData, using: SymmetricKey(key))
    return AuthenticationData(authenticationCode)
}

/// Encrypt data
internal func encrypt(_ data: Data, using key: KeyData) throws -> Data {
    do {
        let authenticationData = Data(SHA512.hash(data: data))
        let sealed = try ChaChaPoly.seal(data, using: SymmetricKey(key), nonce: .init(), authenticating: authenticationData)
        return sealed.combined
    } catch {
        throw AuthenticationError.encryptionError(error)
    }
}

/// Decrypt data
internal func decrypt(_ data: Data, using key: KeyData, authentication: AuthenticationMessage) throws -> Data {
    do {
        let authenticationData = Data(SHA512.hash(data: data))
        let sealed = try ChaChaPoly.SealedBox(combined: data)
        let decrypted = try ChaChaPoly.open(sealed, using: SymmetricKey(key), authenticating: authenticationData)
        return decrypted
    } catch {
        throw AuthenticationError.decryptionError(error)
    }
}

// MARK: - Extensions

public extension KeyData {
    
    internal static var keySize: SymmetricKeySize { .bits256 }
    
    static var length: Int { Self.keySize.bitCount / 8 }
    
    /// Initializes a `Key` with a random value.
    init() {
        let key = SymmetricKey(size: .bits256)
        self.data = key.withUnsafeBytes { Data($0) }
        assert(data.count == Self.length)
    }
}

public extension Nonce {
    
    static var length: Int { 96 / 8 }
    
    init() {
        let nonce = ChaChaPoly.Nonce()
        self.data = Data(nonce)
        assert(data.count == Self.length)
    }
}

public extension Digest {
    
    static var length: Int { SHA512.Digest.byteCount }
    
    init(hash data: Data) {
        let hash = SHA512.hash(data: data)
        self.data = Data(hash)
    }
}

public extension AuthenticationData {
    
    static var length: Int { 32 }
}

internal extension SymmetricKey {
    init(_ key: KeyData) {
        self.init(data: key.data)
    }
}

internal extension ChaChaPoly.Nonce {
    init(_ nonce: CoreLock.Nonce) {
        try! self.init(data: nonce.data)
    }
}

internal extension AuthenticationData {
    init(_ code: HMAC<SHA512>.MAC) {
        self.data = Data(code)
        assert(data.count == Self.length)
    }
}
