//
//  LockConfiguration.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/13/18.
//
//

import Foundation
import CoreLock

#if swift(>=3.2)
#elseif swift(>=3.0)
    import Codable
#endif

/// Stores the lock configuration in a JSON file.
public final class LockConfigurationFile: LockConfigurationStore {
    
    // MARK: - Properties
    
    public let url: URL
    public private(set) var configuration: LockConfiguration
    
    private static let jsonDecoder = JSONDecoder()
    private static let jsonEncoder = JSONEncoder()
    
    // MARK: - Initialization
    
    public init(url: URL) throws {
        
        self.url = url
        
        // attempt to load previous value.
        if let configuration = LockConfigurationFile.read(url: url) {
            
            self.configuration = configuration
            
        } else {
            
            // store new value
            self.configuration = LockConfiguration()
            try self.update(configuration)
        }
    }
    
    // MARK: - Methods
    
    public func update(_ configuration: LockConfiguration) throws {
        
        let data = try type(of: self).jsonEncoder.encode(configuration)
        
        try data.write(to: url, options: .atomic)
        
        self.configuration = configuration
    }
    
    private static func read(url: URL) -> LockConfiguration? {
        
        guard let data = try? Data(contentsOf: url),
            let configuration = try? jsonDecoder.decode(LockConfiguration.self, from: data)
            else { return nil }
        
        return configuration
    }
}

