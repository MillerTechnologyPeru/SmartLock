//
//  KeyEntity.swift
//  LockIntents
//
//  Created by Alsey Coleman Miller on 9/23/22.
//

import AppIntents
import LockKit

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
struct KeyEntity: AppEntity, Identifiable {
    
    /// The unique identifier of the key.
    var id: UUID
    
    /// Lock associated with this key.
    var lock: UUID
    
    /// The name of the key.
    var name: String
    
    /// Date key was created.
    var created: Date
    
    /// Key's permissions.
    var permission: PermissionAppEnum
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension KeyEntity {
    
    static var defaultQuery = KeyQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Key"
    }
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(permission.localizedStringResource)",
            image: .init(named: permission.imageName, isTemplate: false)
        )
    }
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension KeyEntity {
    
    init(key: Key, lock: UUID) {
        self.id = key.id
        self.lock = lock
        self.name = key.name
        self.created = key.created
        self.permission = .init(rawValue: key.permission.type.rawValue)!
    }
}
