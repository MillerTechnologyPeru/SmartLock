//
//  NetworkMonitor.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 10/5/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import Network

/// An observer that you use to monitor and react to network changes.
public final class NetworkMonitor: ObservableObject {
    
    public static let shared = NetworkMonitor()
    
    // MARK: - Properties
    
    private let pathMonitor: NWPathMonitor
    
    public var path: NWPath {
        return pathMonitor.currentPath
    }
    
    // MARK: - Initialization
    
    deinit {
        pathMonitor.cancel()
    }
    
    public init() {
        self.pathMonitor = NWPathMonitor()
        setupPathMonitor()
    }
    
    public init(interface: NWInterface.InterfaceType) {
        self.pathMonitor = NWPathMonitor(requiredInterfaceType: interface)
        setupPathMonitor()
    }
    
    // MARK: - Methods
    
    private func setupPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] _ in
            self?.objectWillChange.send()
        }
        pathMonitor.start(queue: .main)
    }
}
