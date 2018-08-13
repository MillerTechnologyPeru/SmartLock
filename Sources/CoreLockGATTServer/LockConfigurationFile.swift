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

public struct LockConfigurationFile {
    
    private static let jsonEncoder = JSONEncoder()
    private static let jsonDecoder = JSONDecoder()
    
    public var configuration: LockConfiguration
    
    public init(configuration: LockConfiguration) {
        
        self.configuration = configuration
    }
}

