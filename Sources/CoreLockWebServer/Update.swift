//
//  Update.swift
//  CoreLockWebServer
//
//  Created by Alsey Coleman Miller on 10/19/19.
//

import Foundation
import CoreLock
import Kitura

internal extension LockWebServer {
    
    func addUpdateRoute() {
                
        router.post("/update") { [unowned self] (request, response, next) in
            do {
                let statusCode = try self.update(request: request, response: response)
                _ = response.send(status: statusCode)
            }
            catch {
                self.log?("\(request.urlURL.path) Internal server error. \(error.localizedDescription)")
                dump(error)
                _ = response.send(status: .internalServerError)
            }
            try response.end()
        }
    }
    
    private func update(request: RouterRequest, response: RouterResponse) throws -> HTTPStatusCode {
        
        // authenticate
        guard let (key, _) = try authenticate(request: request) else {
            return .unauthorized
        }
        
        // enforce permission
        guard key.permission.isAdministrator else {
            log?("Only lock owner and admins can update")
            return .forbidden
        }
        
        log?("Key \(key.identifier) \(key.name) requested software update")
        
        update?()
        
        return .OK
    }
}
