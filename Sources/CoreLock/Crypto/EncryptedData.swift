//
//  EncryptedData.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import TLVCoding

public struct EncryptedData: Equatable, Hashable, Codable {
    
    /// HMAC signature, signed by secret.
    public let authentication: Authentication
    
    /// Encrypted data
    public let encryptedData: Data
}

public extension EncryptedData {
    
    init(encrypt data: Data, using key: KeyData, id: UUID) throws {
        let digest = Digest(hash: data)
        let message = AuthenticationMessage(digest: digest, id: id)
        let encryptedData = try encrypt(data, using: key, nonce: message.nonce, authentication: message)
        let authentication = Authentication(key: key, message: message)
        self.authentication = authentication
        self.encryptedData = encryptedData
    }
    
    func decrypt(using key: KeyData) throws -> Data {
        // validate HMAC
        guard authentication.isAuthenticated(using: key)
            else { throw AuthenticationError.invalidAuthentication }
        // attempt to decrypt
        return try CoreLock.decrypt(encryptedData, using: key, authentication: authentication.message)
    }
}

extension EncryptedData: TLVCodable {
    
    internal static var authenticationPrefixLength: Int { 176 }
    
    public init?(tlvData: Data) {
        let prefixLength = Self.authenticationPrefixLength
        guard tlvData.count >= prefixLength else {
            return nil
        }
        let prefix = Data(tlvData.prefix(prefixLength))
        guard let authentication = try? TLVDecoder.lock.decode(Authentication.self, from: prefix) else {
            return nil
        }
        self.authentication = authentication
        self.encryptedData = tlvData.count > prefixLength ? Data(tlvData.suffix(from: prefixLength)) : Data()
    }
    
    public var tlvData: Data {
        let authenticationData = try! TLVEncoder.lock.encode(authentication)
        return authenticationData + encryptedData
    }
}
