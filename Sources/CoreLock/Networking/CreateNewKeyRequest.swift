//
//  CreateNewKeyRequest.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 10/16/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
/*
public struct CreateNewKeyNetServiceRequest: Equatable {
    
    /// Lock server
    public let server: URL
    
    /// Authorization header
    public let authorization: LockNetService.Authorization
    
    /// Encrypted request
    public let encryptedData: LockNetService.EncryptedData
}

// MARK: - URL Request

public extension CreateNewKeyNetServiceRequest {
    
    func urlRequest(encoder: JSONEncoder = JSONEncoder()) -> URLRequest {
        
        // http://localhost:8080/keys
        let url = server.appendingPathComponent("key")
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue(authorization.header, forHTTPHeaderField: LockNetService.Authorization.headerField)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try! encoder.encode(encryptedData)
        return urlRequest
    }
}

// MARK: - Encryption

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
        
        let jsonData = try encryptedData.decrypt(using: key)
        return try decoder.decode(CreateNewKeyRequest.self, from: jsonData)
    }
}

// MARK: - Client

public extension LockNetService.Client {
    
    /// Create new key.
    func createKey(_ newKey: CreateNewKeyRequest,
                   for server: LockNetService,
                   with key: KeyCredentials,
                   timeout: TimeInterval = LockNetService.defaultTimeout) throws {
        
        log?("Create \(newKey.permission.type) key \"\(newKey.name)\" \(newKey.identifier) for \(server.url.absoluteString)")
        
        let request = try CreateNewKeyNetServiceRequest(
            server: server.url,
            encrypt: newKey,
            with: key,
            encoder: jsonEncoder
        ).urlRequest(encoder: jsonEncoder)
        
        let (httpResponse, _) = try urlSession.synchronousDataTask(with: request)
        
        guard httpResponse.statusCode == 201
            else { throw LockNetService.Error.statusCode(httpResponse.statusCode) }
    }
}
*/
