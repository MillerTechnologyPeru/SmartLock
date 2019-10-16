//
//  LockNetService.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation
import Bonjour

public struct LockNetService: Equatable, Hashable {
    
    public let identifier: UUID
    
    public let address: NetServiceAddress
}

public extension LockNetService {
    
    var url: URL {
        return URL(string: "http://" + address.description)!
    }
}

public extension LockNetService {
    
    final class Client <NetServiceClient: NetServiceClientProtocol> {
        
        // MARK: - Properties
        
        /// The log message handler.
        public var log: ((String) -> ())?
        
        /// Bonjour Client
        public let bonjour: NetServiceClient
        
        /// URL Session
        public let urlSession: URLSession
        
        /// Whether the client is discovering net services.
        private(set) var isDiscovering = false
        
        internal lazy var jsonDecoder = JSONDecoder()
        
        internal lazy var jsonEncoder = JSONEncoder()
        
        // MARK: - Initialization
        
        public init(bonjour: NetServiceClient,
                    urlSession: URLSession = .shared) {
            
            self.bonjour = bonjour
            self.urlSession = urlSession
        }
        
        // MARK: - Methods
        
        public func discover(duration: TimeInterval = 5.0,
                             timeout: TimeInterval = 10.0) throws -> Set<LockNetService> {
            
            log?("Scanning for \(String(format: "%.2f", duration))s")
            
            isDiscovering = true
            defer { isDiscovering = false }
            
            var foundServices = [UUID: Bonjour.Service](minimumCapacity: 1)
            
            let end = Date() + duration
            try bonjour.discoverServices(of: .lock, in: .local, shouldContinue: {
                Date() < end
            }, foundService: { (service) in
                guard service.type == .lock,
                    let identifier = UUID(uuidString: service.name)
                    else { return }
                foundServices[identifier] = service
            })
            
            var locks = Set<LockNetService>()
            locks.reserveCapacity(foundServices.count)
            
            for (identifier, service) in foundServices {
                
                guard let addresses = try? bonjour.resolve(service, timeout: timeout),
                    let address = addresses.first
                    else { continue }
                
                let lock = LockNetService(
                    identifier: identifier,
                    address: address
                )
                
                locks.insert(lock)
            }
            
            log?("Found \(locks.count) devices")
            
            return locks
        }
        
    }
}

public extension NetServiceType {
        
    static let lock = NetServiceType(rawValue: LockNetService.serviceType)
}

public extension LockNetService {
    
    static let serviceType = "_lock._tcp."
}

public extension LockNetService {
    
    enum Error: Swift.Error {
        
        case invalidURL
        case statusCode(Int)
        case invalidResponse
    }
}
