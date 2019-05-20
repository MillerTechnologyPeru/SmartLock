//
//  NewKey.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/13/18.
//

import Foundation

/// Exportable new key invitation.
public struct NewKey: Codable, Equatable, Hashable {
    
    public let lock: UUID
    
    public let key: Key
    
    public init(lock: UUID,
                key: Key) {
        
        self.lock = lock
        self.key = key
    }
}
