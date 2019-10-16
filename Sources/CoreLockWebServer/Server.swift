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

/// Lock Web Server
public final class LockWebServer {
    
    // MARK: - Properties
    
    public var log: ((String) -> ())?
    
    public var port: Int = 8080
    
    public var hardware: LockHardware = .empty
    
    public var configurationStore: LockConfigurationStore = InMemoryLockConfigurationStore()
    
    public var authorization: LockAuthorizationStore = InMemoryLockAuthorization()
    
    internal let router = Router()
    
    private var httpServer: HTTPServer?
    
    // MARK: - Initialization
    
    public init() {
        setupRouter()
    }
    
    // MARK: - Methods
    
    private func setupRouter() {
        
        addLockInformationRoute()
    }
    
    public func run() {
        
        log?("Started HTTP Server")
        httpServer = Kitura.addHTTPServer(onPort: port, with: router)
        Kitura.run()
    }
}
