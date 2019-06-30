//
//  NewKey.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/13/18.
//

import Foundation

/// Exportable new key invitation.
public struct NewKey: Codable, Equatable, Hashable {
    
    /// Identifier of lock.
    public let lock: UUID
    
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
    
    public init(lock: UUID,
                identifier: UUID = UUID(),
                name: String,
                permission: Permission,
                created: Date = Date(),
                expiration: Date = Date().addingTimeInterval(60 * 60 * 24)) {
        
        self.lock = lock
        self.identifier = identifier
        self.name = name
        self.permission = permission
        self.created = created
        self.expiration = expiration
    }
}
