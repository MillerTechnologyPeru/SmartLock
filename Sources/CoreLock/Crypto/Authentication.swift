//
//  AuthenticationMessage.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

public struct Authentication: Equatable, Codable {
        
    public let message: AuthenticationMessage
    
    public let signedData: AuthenticationData
    
    public init(key: KeyData,
                message: AuthenticationMessage) {
        
        self.message = message
        self.signedData = AuthenticationData(key: key, message: message)
    }
    
    public func isAuthenticated(using key: KeyData) -> Bool {
        return signedData.isAuthenticated(message, using: key)
    }
}

/// HMAC Message
public struct AuthenticationMessage: Equatable, Codable {
    
    public let date: Date
    
    public let nonce: Nonce
    
    public let digest: Digest
    
    public init(
        date: Date = Date(),
        nonce: Nonce = Nonce(),
        digest: Digest
    ) {
        self.date = date
        self.nonce = nonce
        self.digest = digest
    }
}

public extension AuthenticationData {
    
    init(key: KeyData, message: AuthenticationMessage) {
        self = authenticationCode(for: message, using: key)
    }
    
    func isAuthenticated(_ message: AuthenticationMessage, using key: KeyData) -> Bool {
        return data == AuthenticationData(key: key, message: message).data
    }
}
