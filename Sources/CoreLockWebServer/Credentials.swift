//
//  Credentials.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation
import CoreLock
import Kitura

/// Lock  authorization for Web API
public struct LockWebAuthorization: Equatable, Codable {
    
    /// Identifier of key making request.
    public let key: UUID
    
    /// HMAC of key and nonce, and HMAC message
    public let authentication: Authentication
}

public extension LockWebAuthorization {
    
    private static let jsonDecoder = JSONDecoder()
    
    private static let jsonEncoder = JSONEncoder()
    
    init?(header: String) {
        
        guard let data = Data(base64Encoded: header),
            let authorization = try? type(of: self).jsonDecoder.decode(LockWebAuthorization.self, from: data)
            else { return nil }
        
        self = authorization
    }
    
    var header: String {
        let data = try! type(of: self).jsonEncoder.encode(self)
        let base64 = data.base64EncodedString()
        return base64
    }
}

internal extension LockWebAuthorization {
    
    init?(request: RouterRequest) {
        
        guard let authorizationHeader = request.headers["Authorization"],
            let authorization = LockWebAuthorization(header: authorizationHeader) else {
            return nil
        }
        
        self = authorization
    }
}

internal extension LockWebServer {
    
    func authenticate(request: RouterRequest) throws -> Key? {
        
        // authenticate
        guard let authorization = LockWebAuthorization(request: request) else {
            log?("\(request.urlURL.path) Missing authentication")
            return nil
        }
        
        // validate key
        guard let (key, secret) = try self.authorization.key(for: authorization.key) else {
            log?("\(request.urlURL.path) Invalid key \(authorization.key)")
            return nil
        }
        
        // validate HMAC
        guard authorization.authentication.isAuthenticated(with: secret) else {
            log?("\(request.urlURL.path) Invalid HMAC")
            return nil
        }
        
        // guard against replay attacks
        let timestamp = authorization.authentication.message.date
        let now = Date()
        guard timestamp <= now + authorizationTimeout, // cannot be used later for replay attacks
            timestamp > now - authorizationTimeout else { // only valid for 5 seconds
            log?("\(request.urlURL.path) Authentication expired \(timestamp) < \(now)")
            return nil
        }
        
        return key
    }
}
