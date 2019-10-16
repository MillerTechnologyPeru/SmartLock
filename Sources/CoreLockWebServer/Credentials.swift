//
//  Credentials.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation
import CoreLock
import Kitura

internal extension LockNetService.Authorization {
    
    init?(request: RouterRequest) {
        
        guard let authorizationHeader = request.headers[LockNetService.Authorization.headerField],
            let authorization = LockNetService.Authorization(header: authorizationHeader) else {
            return nil
        }
        
        self = authorization
    }
}

internal extension LockWebServer {
    
    func authenticate(request: RouterRequest) throws -> Key? {
        
        // authenticate
        guard let authorization = LockNetService.Authorization(request: request) else {
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
