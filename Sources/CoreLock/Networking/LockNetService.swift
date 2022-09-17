//
//  LockNetService.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//
/*
import Foundation
import Bonjour

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct LockNetService: Equatable, Hashable {
    
    public let id: UUID
    
    public let url: URL
}

internal extension LockNetService {
    
    init(id: UUID, address: NetServiceAddress) {
        
        guard let url = URL(string: "http://" + address.description)
            else { fatalError("Could not create URL from \(address)") }
        
        self.id = id
        self.url = url
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
                    let address = addresses.filter({
                        switch $0.address {
                        case .ipv4: return true
                        case .ipv6: return false
                        }
                    }).first
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

// MARK: - Extensions

public extension NetServiceType {
        
    static let lock = NetServiceType(rawValue: LockNetService.serviceType)
}

public extension LockNetService {
    
    static let serviceType = "_lock._tcp."
    
    static var defaultTimeout: TimeInterval = 30.0
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
    struct Authorization: Equatable, Codable {
        
        /// Identifier of key making request.
        public let key: UUID
        
        /// HMAC of key and nonce, and HMAC message
        public let authentication: Authentication
    }
}

public extension LockNetService.Authorization {
    
    init(key: KeyCredentials) {
        
        self.init(key: key.identifier, authentication: Authentication(key: key.secret))
    }
}

public extension LockNetService.Authorization {
    
    private static let jsonDecoder = JSONDecoder()
    
    private static let jsonEncoder = JSONEncoder()
    
    static let headerField: String = "Authorization"
    
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

public extension LockNetService {
    
    struct EncryptedData: Equatable, Codable {
        
        internal enum CodingKeys: String, CodingKey {
            
            case initializationVector = "iv"
            case encryptedData = "data"
        }
        
        /// Crypto IV
        public let initializationVector: InitializationVector
        
        /// Encrypted data
        public let encryptedData: Data
    }
}

extension LockNetService.EncryptedData {
    
    init(encrypt data: Data, with key: KeyData) throws {
        
        do {
            let (encryptedData, iv) = try CoreLock.encrypt(key: key.data, data: data)
            self.initializationVector = iv
            self.encryptedData = encryptedData
        }
        catch { throw AuthenticationError.encryptionError(error) }
    }
    
    func decrypt(with key: KeyData) throws -> Data {
        
        // attempt to decrypt
        do { return try CoreLock.decrypt(key: key.data, iv: initializationVector, data: encryptedData) }
        catch { throw AuthenticationError.decryptionError(error) }
    }
}
*/
