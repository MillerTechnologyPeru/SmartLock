//
//  UpdateRequest.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 10/18/19.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
/*
/// Lock Software Update HTTP Request
public struct UpdateNetServiceRequest: Equatable {
    
    /// Lock server
    public let server: URL
    
    /// Authorization header
    public let authorization: LockNetService.Authorization
}

// MARK: - URL Request

public extension UpdateNetServiceRequest {
    
    func urlRequest() -> URLRequest {
        
        // http://localhost:8080/update
        let url = server.appendingPathComponent("update")
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue(authorization.header, forHTTPHeaderField: LockNetService.Authorization.headerField)
        urlRequest.httpMethod = "POST"
        return urlRequest
    }
}

// MARK: - Client

public extension LockNetService.Client {
    
    /// Create new key.
    func update(for server: LockNetService,
                with key: KeyCredentials,
                timeout: TimeInterval = LockNetService.defaultTimeout) throws {
        
        log?("Update software for \(server.url.absoluteString)")
        
        let request = UpdateNetServiceRequest(
            server: server.url,
            authorization: .init(key: key)
        ).urlRequest()
        
        let (httpResponse, _) = try urlSession.synchronousDataTask(with: request)
        
        guard httpResponse.statusCode == 200
            else { throw LockNetService.Error.statusCode(httpResponse.statusCode) }
    }
}
*/
