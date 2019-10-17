//
//  CreateNewKeyRequest.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 10/16/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CryptoSwift

public struct CreateNewKeyNetServiceRequest: Equatable {
    
    /// Lock server
    public let server: URL
    
    /// Authorization header
    public let authorization: LockNetService.Authorization
    
    /// Encrypted request
    public let encryptedData: LockNetService.EncryptedData
}

public extension CreateNewKeyNetServiceRequest {
    
    init(server: URL,
         encrypt value: CreateNewKeyRequest,
         with key: KeyCredentials,
         encoder: JSONEncoder = JSONEncoder()) throws {
        
        self.server = server
        self.authorization = LockNetService.Authorization(key: key)
        let data = try encoder.encode(value)
        self.encryptedData = try .init(encrypt: data, with: key.secret)
    }
    
    static func decrypt(_ encryptedData: LockNetService.EncryptedData,
                        with key: KeyData,
                        decoder: JSONDecoder = JSONDecoder()) throws -> CreateNewKeyRequest {
        
        let jsonData = try encryptedData.decrypt(with: key)
        return try decoder.decode(CreateNewKeyRequest.self, from: jsonData)
    }
}
