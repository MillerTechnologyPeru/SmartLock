//
//  Permissions.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation
import CoreLock
import Kitura

internal extension LockWebServer {
    
    func addPermissionsRoute() {
                
        router.post("/key") { [unowned self] (request, response, next) in
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
        
        router.get("/key") { [unowned self] (request, response, next) in
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
        
        router.delete("/key/:id") { [unowned self] (request, response, next) in
            guard let identifierString = request.parameters["id"],
                let identifier = UUID(uuidString: identifierString) else {
                _ = response.send(status: .notFound)
                try response.end()
                    return
            }
            do {
                let statusCode = try self.deleteKey(identifier, type: .key, request: request, response: response)
                _ = response.send(status: statusCode)
            }
            catch {
                self.log?("\(request.urlURL.path) Internal server error. \(error.localizedDescription)")
                dump(error)
                _ = response.send(status: .internalServerError)
            }
            try response.end()
        }
        
        router.delete("/newKey/:id") { [unowned self] (request, response, next) in
            guard let identifierString = request.parameters["id"],
                let identifier = UUID(uuidString: identifierString) else {
                _ = response.send(status: .notFound)
                try response.end()
                    return
            }
            do {
                let statusCode = try self.deleteKey(identifier, type: .newKey, request: request, response: response)
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
    
    private func getKeys(request: RouterRequest, response: RouterResponse) throws -> HTTPStatusCode? {
        
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
    
    private func createKey(request: RouterRequest, response: RouterResponse) throws -> HTTPStatusCode {
        
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
    
    private func deleteKey(_ id: UUID, type: KeyType, request: RouterRequest, response: RouterResponse) throws -> HTTPStatusCode {
        
        // authenticate
        guard let (key, _) = try authenticate(request: request) else {
            return .unauthorized
        }
        
        // enforce permission
        guard key.permission.isAdministrator else {
            log?("Only lock owner and admins can remove keys")
            return .forbidden
        }
        
        switch type {
        case .key:
            guard let (removeKey, _) = try authorization.key(for: identifier)
                else { log?("Key \(identifier) does not exist"); return .notFound }
            assert(removeKey.identifier == identifier)
            try authorization.removeKey(removeKey.identifier)
        case .newKey:
            guard let (removeKey, _) = try authorization.newKey(for: identifier)
                else { log?("New Key \(identifier) does not exist"); return .notFound }
            assert(removeKey.identifier == identifier)
            try authorization.removeNewKey(removeKey.identifier)
        }
        
        log?("Key \(key.identifier) \(key.name) removed \(type) \(identifier)")
        
        try events.save(.removeKey(.init(key: key.identifier, removedKey: identifier, type: type)))
        
        lockChanged?()
        
        return .OK
    }
}
