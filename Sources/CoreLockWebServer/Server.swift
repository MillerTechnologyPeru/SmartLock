//
//  Server.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation
import Dispatch
import CoreLock
import Kitura
import KituraNet

#if os(Linux)
import NetService
#endif

/// Lock Web Server
public final class LockWebServer {
    
    // MARK: - Properties
    
    public var log: ((String) -> ())?
    
    public var port: Int = 8080
    
    public var hardware: LockHardware = .empty
    
    public var configurationStore: LockConfigurationStore = InMemoryLockConfigurationStore()
    
    public var authorization: LockAuthorizationStore = InMemoryLockAuthorization()
    
    public var authorizationTimeout: TimeInterval = 10.0
    
    public var events: LockEventStore = InMemoryLockEvents()
    
    public var lockChanged: (() -> ())?
    
    public var update: (() -> ())?
    
    internal lazy var jsonEncoder = JSONEncoder()
    
    internal lazy var jsonDecoder = JSONDecoder()
    
    internal let router = Router()
    
    private var httpServer: HTTPServer?
    
    private var netService: NetService?
        
    // MARK: - Initialization
    
    public init() {
        setupRouter()
    }
    
    // MARK: - Methods
    
    private func setupRouter() {
        
        addLockInformationRoute()
        addPermissionsRoute()
        addEventsRoute()
        addUpdateRoute()
    }
    
    public func run() {
        
        // Bonjour
        netService = NetService(domain: "local.",
                                type: LockNetService.serviceType,
                                name: configurationStore.configuration.identifier.uuidString,
                                port: Int32(port))
        
        netService?.publish(options: [])
        
        // Kiture
        httpServer = Kitura.addHTTPServer(onPort: port, with: router)
        log?("Started HTTP Server on port \(port)")
        Kitura.run()
    }
}
