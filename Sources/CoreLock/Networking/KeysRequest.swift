//
//  KeysRequest.swift
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
public struct KeysNetServiceRequest: Equatable {
    
    /// Lock server
    public let server: URL
    
    /// Authorization header
    public let authorization: LockNetService.Authorization
}

// MARK: - URL Request

public extension KeysNetServiceRequest {
    
    func urlRequest() -> URLRequest {
        
        // http://localhost:8080/keys
        let url = server.appendingPathComponent("key")
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue(authorization.header, forHTTPHeaderField: LockNetService.Authorization.headerField)
        return urlRequest
    }
}

// MARK: - Client

public extension LockNetService.Client {
    
    /// Retreive a list of all keys on device.
    func listKeys(for server: LockNetService,
                  with key: KeyCredentials,
                  timeout: TimeInterval = LockNetService.defaultTimeout) throws -> KeysList {
        
        log?("List keys for \(server.url.absoluteString)")
        
        let request = KeysNetServiceRequest(
            server: server.url,
            authorization: LockNetService.Authorization(
                key: key.identifier,
                authentication: Authentication(key: key.secret)
            )
        )
        
        let (httpResponse, data) = try urlSession.synchronousDataTask(with: request.urlRequest())
        
        guard httpResponse.statusCode == 200
            else { throw LockNetService.Error.statusCode(httpResponse.statusCode) }
        
        guard let jsonData = data,
            let response = try? jsonDecoder.decode(KeysResponse.self, from: jsonData)
            else { throw LockNetService.Error.invalidResponse }
        
        let keys = try response.decrypt(using: key.secret, decoder: jsonDecoder)
        return keys
    }
}
*/
