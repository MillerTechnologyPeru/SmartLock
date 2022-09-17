//
//  DeleteKeyRequest.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 10/19/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
/*
/// Lock Software Update HTTP Request
public struct DeleteKeyRequest: Equatable {
    
    /// Lock server
    public let server: URL
    
    /// Authorization header
    public let authorization: LockNetService.Authorization
    
    /// Key to delete
    public let key: UUID
    
    /// Type of Key to delete
    public let type: KeyType
}

// MARK: - URL Request

public extension DeleteKeyRequest {
    
    func urlRequest() -> URLRequest {
        
        // http://localhost:8080/key/A6E3EC9B-FD6E-4A50-B459-51CFDA2A21DD
        let url = server
            .appendingPathComponent(type.stringValue)
            .appendingPathComponent(key.uuidString)
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue(authorization.header, forHTTPHeaderField: LockNetService.Authorization.headerField)
        urlRequest.httpMethod = "DELETE"
        return urlRequest
    }
}

// MARK: - Client

public extension LockNetService.Client {
    
    /// Remove the specified key.
    func removeKey(_ id: UUID,
                   type: KeyType = .key,
                   for server: LockNetService,
                   with key: KeyCredentials,
                   timeout: TimeInterval = LockNetService.defaultTimeout) throws {
        
        log?("Remove \(type) \(identifier) for \(server.url.absoluteString)")
        
        let request = DeleteKeyRequest(
            server: server.url,
            authorization: .init(key: key),
            key: identifier,
            type: type
        ).urlRequest()
        
        let (httpResponse, _) = try urlSession.synchronousDataTask(with: request)
        
        guard httpResponse.statusCode == 200
            else { throw LockNetService.Error.statusCode(httpResponse.statusCode) }
    }
}
*/
