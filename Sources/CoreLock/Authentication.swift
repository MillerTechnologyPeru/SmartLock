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
                message: AuthenticationMessage = AuthenticationMessage()) {
        
        self.message = message
        self.signedData = AuthenticationData(key: key, message: message)
    }
    
    public func isAuthenticated(with key: KeyData) -> Bool {
        
        return signedData.isAuthenticated(with: key, message: message)
    }
}

/// HMAC Message
public struct AuthenticationMessage: Equatable, Codable {
    
    public let date: Date
    
    public let nonce: Nonce
    
    public init(date: Date = Date(),
                nonce: Nonce = Nonce()) {
        
        self.date = date
        self.nonce = nonce
    }
}

/// HMAC data
public struct AuthenticationData: Equatable {
    
    internal static let length = HMACSize
    
    public let data: Data
    
    public init?(data: Data) {
        
        guard data.count == type(of: self).length
            else { return nil }
        
        self.data = data
    }
    
    public init(key: KeyData, message: AuthenticationMessage) {
        
        self = HMAC(key: key, message: message)
    }
    
    public func isAuthenticated(with key: KeyData, message: AuthenticationMessage) -> Bool {
        
        return data == AuthenticationData(key: key, message: message).data
    }
}

extension AuthenticationData: Codable {
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        guard let value = AuthenticationData(data: data) else {
            throw DecodingError.typeMismatch(AuthenticationData.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid number of bytes \(data.count) for \(String(reflecting: AuthenticationData.self))"))
        }
        self = value
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}
