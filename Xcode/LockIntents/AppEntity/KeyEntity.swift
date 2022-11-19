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
    let id: UUID
    
    /// Lock associated with this key.
    let lock: UUID
    
    /// The name of the key.
    let name: String
    
    /// Date key was created.
    let created: Date
    
    /// Key's permissions.
    let permission: PermissionAppEnum
    
    let isPending: Bool
    
    let expiration: Date?
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension KeyEntity {
    
    static var defaultQuery = KeyQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Key"
    }
    
    @MainActor
    var displayRepresentation: DisplayRepresentation {
        let lock = Store.shared.applicationData.locks[lock]?.name
        return DisplayRepresentation(
            title: lock.map { "\($0) - \(name)" } ?? "\(name)",
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
        self.isPending = false
        self.expiration = nil
    }
    
    init(newKey: NewKey, lock: UUID) {
        self.id = newKey.id
        self.lock = lock
        self.name = newKey.name
        self.created = newKey.created
        self.permission = .init(rawValue: newKey.permission.type.rawValue)!
        self.isPending = true
        self.expiration = newKey.expiration
    }
}
