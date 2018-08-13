//
//  NewKey.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/13/18.
//

import Foundation

/// Exportable new key invitation.
public struct NewKey {
    
    public let lock: UUID
    
    public let key: Key
    
    public init(lock: UUID,
                key: Key) {
        
        self.lock = lock
        self.key = key
    }
}

// MARK: - Equatable

extension NewKey: Equatable {
    
    public static func == (lhs: NewKey, rhs: NewKey) -> Bool {
        
        return lhs.lock == rhs.lock
            && lhs.key == rhs.key
    }
}


