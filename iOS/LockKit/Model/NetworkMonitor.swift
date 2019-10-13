//
//  NetworkMonitor.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 10/5/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import Network

@available(iOS 12.0, watchOS 5.0, *)
public final class NetworkMonitor {
    
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
            if #available(iOS 13.0, watchOS 6.0,  *) {
                self?.objectWillChange.send()
            }
        }
        pathMonitor.start(queue: .main)
    }
}

// MARK: - ObservableObject

@available(iOS 13.0, watchOS 6.0,  *)
extension NetworkMonitor: ObservableObject { }
