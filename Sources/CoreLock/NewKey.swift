//
//  NewKey.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/13/18.
//

import Foundation

/// New Key
public struct NewKey: Codable, Equatable, Hashable {
    
    /// The unique identifier of the key.
    public let identifier: UUID
    
    /// The name of the key.
    public let name: String
    
    /// Key's permissions.
    public let permission: Permission
    
    /// Date new key invitation was created.
    public let created: Date
    
    /// Expiration date for new key invitation.
    public let expiration: Date
    
    public init(identifier: UUID = UUID(),
                name: String = "",
                permission: Permission = .anytime,
                created: Date = Date(),
                expiration: Date = Date().addingTimeInterval(60 * 60 * 24)) {
        
        self.identifier = identifier
        self.name = name
        self.permission = permission
        self.created = created
        self.expiration = expiration
    }
}

public extension NewKey {
    
    /// Exportable new key invitation.
    struct Invitation: Codable, Equatable {
        
        /// Identifier of lock.
        public let lock: UUID
        
        /// New Key to create.
        public let key: NewKey
        
        public init(lock: UUID, key: NewKey) {
            
            self.lock = lock
            self.key = key
        }
    }
}
