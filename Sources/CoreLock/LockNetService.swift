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
    
    final class Client <Client: NetServiceClientProtocol> {
        
        // MARK: - Properties
        
        /// The log message handler.
        public var log: ((String) -> ())?
        
        /// Bonjour Client
        public let bonjour: Client
        
        private(set) var isDiscovering = false
        
        // MARK: - Initialization
        
        public init(bonjour: Client) {
            self.bonjour = bonjour
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
    
    struct LockInformation: Equatable, Codable {
        
        /// Lock identifier
        public let identifier: UUID
        
        /// Firmware build number
        public let buildVersion: LockBuildVersion
        
        /// Firmware version
        public let version: LockVersion
        
        /// Device state
        public var status: LockStatus
        
        /// Supported lock actions
        public let unlockActions: Set<UnlockAction>
        
        public init(identifier: UUID,
                    buildVersion: LockBuildVersion = .current,
                    version: LockVersion = .current,
                    status: LockStatus,
                    unlockActions: Set<UnlockAction> = [.default]) {
            
            self.identifier = identifier
            self.buildVersion = buildVersion
            self.version = version
            self.status = status
            self.unlockActions = unlockActions
        }
    }
}
