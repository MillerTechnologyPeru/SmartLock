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
        
        router.post("/keys") { [unowned self] (request, response, next) in
            try self.createKey(request: request, response: response)
            try response.end()
        }
    }
    
    func getKeys(request: RouterRequest, response: RouterResponse) throws {
        
        // authenticate
        guard let (key, secret) = try authenticate(request: request) else {
            _ = response.send(status: .unauthorized)
            return
        }
        
        // enforce permission
        guard key.permission.isAdministrator else {
            log?("Only lock owner and admins can view list of keys")
            _ = response.send(status: .forbidden)
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
    
    func createKey(request: RouterRequest, response: RouterResponse) throws {
        
        // authenticate
        guard let (key, secret) = try authenticate(request: request) else {
            _ = response.send(status: .unauthorized)
            return
        }
        
        // enforce permission
        guard key.permission.isAdministrator else {
            log?("Only lock owner and admins can view list of keys")
            _ = response.send(status: .forbidden)
            return
        }
        
        // parse body
        let encryptedData = try request.read(as: LockNetService.EncryptedData.self)
        let newKeyRequest = try CreateNewKeyNetServiceRequest.decrypt(
            encryptedData,
            with: secret,
            decoder: jsonDecoder
        )
        let newKey = NewKey(request: newKeyRequest)
        
        log?("Create \(newKey.permission.type) key \"\(newKey.name)\" \(newKey.identifier)")
        
        try self.authorization.add(newKey, secret: newKeyRequest.secret)
        
        try events.save(.createNewKey(.init(key: key.identifier, newKey: newKey.identifier)))
        
        lockChanged?()
        
        _ = response.send(status: .created)
    }
}
