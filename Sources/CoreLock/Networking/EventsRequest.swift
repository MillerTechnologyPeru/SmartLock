//
//  EventsRequest.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 10/20/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
/*
public struct EventsNetServiceRequest: Equatable {
    
    /// Lock server
    public let server: URL
    
    /// Authorization header
    public let authorization: LockNetService.Authorization
    
    /// Encrypted request
    public let fetchRequest: LockEvent.FetchRequest?
}

// MARK: - URL Request

public extension EventsNetServiceRequest {
    
    func urlRequest() -> URLRequest {
        
        // http://localhost:8080/event
        guard var urlComponents = URLComponents(url: server.appendingPathComponent("event"), resolvingAgainstBaseURL: false)
            else { fatalError() }
        urlComponents.queryItems = fetchRequest?.queryItems
        guard let url = urlComponents.url
            else { fatalError() }
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue(authorization.header, forHTTPHeaderField: LockNetService.Authorization.headerField)
        urlRequest.httpMethod = "GET"
        return urlRequest
    }
}

public extension LockEvent.FetchRequest {
    
    init?(queryItems: [URLQueryItem]) {
        guard let offset = queryItems.first(.offset).flatMap(UInt8.init)
            else { return nil }
        self.offset = offset
        self.limit = queryItems.first(.limit).flatMap(UInt8.init)
        var predicate = LockEvent.Predicate.empty
        predicate.start = queryItems.firstDate(.start)
        predicate.end = queryItems.firstDate(.end)
        predicate.keys = queryItems
            .compactMap(.key)
            .compactMap { UUID(uuidString: $0) }
        self.predicate = predicate != .empty ? predicate : nil
    }
    
    var queryItems: [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        queryItems.reserveCapacity(3)
        queryItems.append(.init(name: .offset, value: offset.description))
        limit.flatMap { queryItems.append(.init(name: .limit, value: $0.description)) }
        if let predicate = predicate {
            predicate.keys.flatMap {
                queryItems += $0.map { .init(name: .key, value: $0.uuidString) }
            }
            predicate.start.flatMap { queryItems.append(.init(name: .start, value: $0)) }
            predicate.end.flatMap { queryItems.append(.init(name: .end, value: $0)) }
        }
        return queryItems
    }
}

internal extension EventsNetServiceRequest {
    
    enum QueryItem: String {
        case offset
        case limit
        case key
        case start
        case end
    }
}

internal extension URLQueryItem {
    
    init(name: EventsNetServiceRequest.QueryItem, value: String? = nil) {
        self.init(name: name.rawValue, value: value)
    }
    
    init(name: EventsNetServiceRequest.QueryItem, value date: Date) {
        let value = Int(date.timeIntervalSince1970).description
        self.init(name: name, value: value)
    }
}

internal extension Sequence where Self.Element == URLQueryItem {
    
    func first(_ name: EventsNetServiceRequest.QueryItem) -> String? {
        return first(where: { $0.name == name.rawValue })?.value
    }
    
    func compactMap(_ name: EventsNetServiceRequest.QueryItem) -> [String] {
        return compactMap { $0.name == name.rawValue ? $0.value : nil }
    }
    
    func firstDate(_ name: EventsNetServiceRequest.QueryItem) -> Date? {
        guard let value = first(name),
            let timeInterval = TimeInterval(value)
            else { return nil }
        return Date(timeIntervalSince1970: timeInterval)
    }
}

// MARK: - Client

public extension LockNetService.Client {
    
    /// Retreive a list of events on device.
    func listEvents(fetchRequest: LockEvent.FetchRequest? = nil,
                    for server: LockNetService,
                    with key: KeyCredentials,
                    timeout: TimeInterval = LockNetService.defaultTimeout) throws -> EventsList {
        
        log?("List events for \(server.url.absoluteString)")
        
        let request = EventsNetServiceRequest(
            server: server.url,
            authorization: LockNetService.Authorization(key: key),
            fetchRequest: fetchRequest
        )
        
        let (httpResponse, data) = try urlSession.synchronousDataTask(with: request.urlRequest())
        
        guard httpResponse.statusCode == 200
            else { throw LockNetService.Error.statusCode(httpResponse.statusCode) }
        
        guard let jsonData = data,
            let response = try? jsonDecoder.decode(EventsResponse.self, from: jsonData)
            else { throw LockNetService.Error.invalidResponse }
        
        let keys = try response.decrypt(with: key.secret, decoder: jsonDecoder)
        return keys
    }
}
*/
