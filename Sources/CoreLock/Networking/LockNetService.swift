//
//  LockNetService.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTP
//import Bonjour

public struct LockNetService: Equatable, Hashable {
    
    public let id: UUID
    
    public let url: URL
}
/*
internal extension LockNetService {
    
    init(id: UUID, address: NetServiceAddress) {
        
        guard let url = URL(string: "http://" + address.description)
            else { fatalError("Could not create URL from \(address)") }
        
        self.id = id
        self.url = url
    }
}
*/
public extension LockNetService {
    
    static let serviceType = "_lock._tcp."
}

// MARK: - Supporting Types

public extension LockNetService {
    
    enum Error: Swift.Error {
        
        case invalidURL
        case statusCode(Int)
        case invalidResponse
    }
}

public extension LockNetService {
    
    /// Lock  authorization for Web API
    typealias Authorization = CoreLock.Authentication
}

/*
public extension LockNetService.Authorization {
    
    init(key: KeyCredentials) {
        
        self.init(key: key.id, authentication: Authentication(key: key.secret))
    }
}
*/
public extension LockNetService.Authorization {
    
    private static let jsonDecoder = JSONDecoder()
    
    private static let jsonEncoder = JSONEncoder()
        
    init?(header: String) {
        
        guard let data = Data(base64Encoded: header),
            let authorization = try? type(of: self).jsonDecoder.decode(LockNetService.Authorization.self, from: data)
            else { return nil }
        
        self = authorization
    }
    
    var header: String {
        let data = try! type(of: self).jsonEncoder.encode(self)
        let base64 = data.base64EncodedString()
        return base64
    }
}
