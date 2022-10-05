//
//  NetServiceURL.swift
//  
//
//  Created by Alsey Coleman Miller on 10/5/22.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTP

public extension LockNetService {
    
    enum URL: Equatable, Hashable {
        
        /// Lock Information
        case information
        
        /// List Events
        case events(LockEvent.FetchRequest? = nil)
        
        /// List Keys
        case keys
        
        /// Create New Key
        case newKey
        
        /// Delete Key
        case deleteKey(UUID, KeyType)
    }
}

public extension LockNetService.URL {
    
    /// Build a Lock Net Service request URL provided the server base URL.
    func url(for server: URL) -> URL {
        var url = server
        // build path
        pathComponents.forEach {
            url.appendPathComponent($0)
        }
        // add query items
        let queryItems = self.queryItems
        if queryItems.isEmpty == false {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = queryItems
            url = urlComponents?.url ?? url
        }
        return url
    }
    
    var pathComponents: [String] {
        switch self {
        case .information:
            return ["info"]
        case .events:
            return ["event"]
        case .keys:
            return [KeyType.key.stringValue]
        case .newKey:
            return [KeyType.key.stringValue]
        case let .deleteKey(id, type):
            return [type.stringValue, id.description]
        }
    }
    
    var queryItems: [URLQueryItem] {
        switch self {
        case let .events(fetchRequest):
            return fetchRequest?.queryItems ?? []
        default:
            return []
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .information:
            return .get
        case .events:
            return .get
        case .keys:
            return .get
        case .newKey:
            return .post
        case .deleteKey:
            return .delete
        }
    }
}
