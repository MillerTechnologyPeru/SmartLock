//
//  Key.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

/// A smart lock key.
public struct Key: Codable, Equatable, Hashable {
    
    /// The unique identifier of the key.
    public let identifier: UUID
    
    /// The name of the key.
    public let name: String
    
    /// Date key was created.
    public let date: Date
    
    /// Key's permissions. 
    public let permission: Permission
    
    public init(identifier: UUID = UUID(),
                name: String = "",
                date: Date = Date(),
                permission: Permission) {
        
        self.identifier = identifier
        self.name = name
        self.date = date
        self.permission = permission
    }
}
