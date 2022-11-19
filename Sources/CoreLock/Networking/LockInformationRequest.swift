//
//  LockInformationRequest.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 10/16/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTP

/// Lock Information Web Request
public struct LockInformationNetServiceRequest: Equatable, Hashable {
    
    /// Lock server
    public let server: URL
}

public extension LockInformationNetServiceRequest {
    
    func urlRequest() -> URLRequest {
        // http://localhost:8080/info
        let url = server.appendingPathComponent("info")
        return URLRequest(url: url)
    }
}

/*
public extension LockNetService.Client {
    
    /// Read the lock's information characteristic.
    func readInformation(
        for server: LockNetService,
        timeout: TimeInterval = LockNetService.defaultTimeout
    ) async throws -> LockNetService.LockInformation {
        
    }
}
 
public extension HTTPClient {
    
    /// Read the lock's information characteristic.
    func readInformation(
        for server: URL
    ) async throws -> LockNetService.LockInformation {
        //log?("Read information for \(server.url.absoluteString)")
        let request = LockInformationNetServiceRequest(server: server).urlRequest()
        let (httpResponse, data) = try await self.data(for: request)
        guard httpResponse.statusCode == 200
            else { throw LockNetService.Error.statusCode(httpResponse.statusCode) }
        guard let jsonData = data,
            let response = try? jsonDecoder.decode(LockNetService.LockInformation.self, from: jsonData)
            else { throw LockNetService.Error.invalidResponse }
        return response
    }
}
*/
