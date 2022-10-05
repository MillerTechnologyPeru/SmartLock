//
//  NetServiceURL.swift
//  
//
//  Created by Alsey Coleman Miller on 10/5/22.
//

import Foundation

public extension LockNetService {
    
    enum URL: Equatable, Hashable {
        
        /// Lock Information
        case information
        
        /// List Events
        case events
        
        /// List Keys
        case keys
        
        /// Create New Key
        case newKey
        
        /// Delete Key
        case deleteKey(UUID, KeyType)
    }
}
