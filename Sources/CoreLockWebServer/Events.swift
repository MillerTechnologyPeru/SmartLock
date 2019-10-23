//
//  Events.swift
//  CoreLockWebServer
//
//  Created by Alsey Coleman Miller on 10/22/19.
//

import Foundation
import CoreLock
import Kitura

internal extension LockWebServer {
    
    func addEventsRoute() {
        
        router.get("/event") { [unowned self] (request, response, next) in
            do {
                if let statusCode = try self.getEvents(request: request, response: response) {
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
    
    private func getEvents(request: RouterRequest, response: RouterResponse) throws -> HTTPStatusCode? {
        
        // authenticate
        guard let (key, secret) = try authenticate(request: request) else {
            return .unauthorized
        }
        
        log?("Key \(key.identifier) \(key.name) requested events list")
        
        var fetchRequest = LockEvent.FetchRequest()
        
        if let urlComponents = URLComponents(url: request.urlURL, resolvingAgainstBaseURL: true),
            let queryItems = urlComponents.queryItems,
            let queryFetchRequest = LockEvent.FetchRequest(queryItems: queryItems) {
            var fetchDescription = ""
            dump(fetchRequest, to: &fetchDescription)
            log?(fetchDescription)
            fetchRequest = queryFetchRequest
        }
        
        // enforce permission, non-administrators can only view their own events.
        if key.permission.isAdministrator == false {
            var predicate = fetchRequest.predicate ?? .empty
            predicate.keys = [key.identifier]
            fetchRequest.predicate = predicate
        }
        
        // execute fetch
        let list = try events.fetch(fetchRequest)
        
        // encrypt
        let eventsResponse = try EventsResponse(encrypt: list, with: secret, encoder: jsonEncoder)
        
        // respond
        response.send(eventsResponse)
        return nil
    }
}
