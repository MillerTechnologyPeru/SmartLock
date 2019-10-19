//
//  Permissions.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation
import CoreLock
import Kitura
import KituraNet

internal extension LockWebServer {
    
    func addPermissionsRoute() {
                
        router.post("/keys") { [unowned self] (request, response, next) in
            do {
                let statusCode = try self.createKey(request: request, response: response)
                _ = response.send(status: statusCode)
            }
            catch {
                self.log?("\(request.urlURL.path) Internal server error. \(error.localizedDescription)")
                dump(error)
                _ = response.send(status: .internalServerError)
            }
            try response.end()
        }
        
        router.get("/keys") { [unowned self] (request, response, next) in
            do {
                if let statusCode = try self.getKeys(request: request, response: response) {
                    _ = response.send(status: statusCode)
                }
            }
            catch {
                self.log?("\(request.urlURL.path) Internal server error. \(error.localizedDescription)")
                dump(error)
                _ = response.send(status: .internalServerError)
            }
            try response.end()
        }
    }
    
    func getKeys(request: RouterRequest, response: RouterResponse) throws -> HTTPStatusCode? {
        
        // authenticate
        guard let (key, secret) = try authenticate(request: request) else {
            return .unauthorized
        }
        
        // enforce permission
        guard key.permission.isAdministrator else {
            log?("Only lock owner and admins can view list of keys")
            return .forbidden
        }
        
        log?("Key \(key.identifier) \(key.name) requested keys list")
        
        // get list
        let list = authorization.list
        
        // encrypt
        let keysResponse = try KeysResponse(encrypt: list, with: secret, encoder: jsonEncoder)
        
        // respond
        response.send(keysResponse)
        return nil
    }
    
    func createKey(request: RouterRequest, response: RouterResponse) throws -> HTTPStatusCode {
        
        // authenticate
        guard let (key, secret) = try authenticate(request: request) else {
            return .unauthorized
        }
        
        // enforce permission
        guard key.permission.isAdministrator else {
            log?("Only lock owner and admins can view list of keys")
            return .forbidden
        }
        
        // parse body
        var data = Data()
        _ = try request.read(into: &data)
        let encryptedData = try jsonDecoder.decode(LockNetService.EncryptedData.self, from: data)
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
        
        return .created
    }
}
