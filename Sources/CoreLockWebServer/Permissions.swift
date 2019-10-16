//
//  Permissions.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation
import CoreLock
import Kitura
import KituraContracts

internal extension LockWebServer {
    
    func addPermissionsRoute() {
        
        router.get("/keys") { [unowned self] (request, response, next) in
            try self.getKeys(request: request, response: response)
            try response.end()
        }
    }
    
    func getKeys(request: RouterRequest, response: RouterResponse) throws {
        
        // authenticate
        guard let (key, secret) = try authenticate(request: request) else {
            response.status(.unauthorized)
            return
        }
        
        // enforce permission
        guard key.permission.isAdministrator else {
            log?("Only lock owner and admins can view list of keys")
            response.status(.forbidden)
            return
        }
        
        log?("Key \(key.identifier) \(key.name) requested keys list")
        
        // get list
        let list = authorization.list
        
        // encrypt
        let keysResponse = try KeysResponse(encrypt: list, with: secret, encoder: jsonEncoder)
        
        // respond
        response.send(keysResponse)
    }
}
