//
//  EncryptedData.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

public struct EncryptedData: Equatable, Codable {
    
    /// HMAC signature, signed by secret.
    public let authentication: Authentication
    
    /// Encrypted data
    public let encryptedData: Data
}

public extension EncryptedData {
    
    init(encrypt data: Data, with key: KeyData) throws {
        let digest = Digest(hash: data)
        let message = AuthenticationMessage(digest: digest)
        let encryptedData = try encrypt(data, using: key, nonce: message.nonce)
        let authentication = Authentication(key: key, message: message)
        self.authentication = authentication
        self.encryptedData = encryptedData
    }
    
    func decrypt(with key: KeyData) throws -> Data {
        // validate HMAC
        guard authentication.isAuthenticated(using: key)
            else { throw AuthenticationError.invalidAuthentication }
        // attempt to decrypt
        return try CoreLock.decrypt(encryptedData, using: key)
    }
}
