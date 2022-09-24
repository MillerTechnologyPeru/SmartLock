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
    var permission: Permission
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

// MARK: - Supporting Types

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension KeyEntity {
    
    enum Permission: UInt8, AppEnum {
        
        case owner          = 0x00
        case admin          = 0x01
        case anytime        = 0x02
        case scheduled      = 0x03
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation {
            "Permission"
        }
        
        static var caseDisplayRepresentations: [Permission : DisplayRepresentation] {
            [
                .owner: "Owner",
                .admin: "Admin",
                .anytime: "Anytime",
                .scheduled: "Scheduled"
            ]
        }
        
        var imageName: String {
            switch self {
            case .owner:
                return "permissionOwner"
            case .admin:
                return "permissionAdmin"
            case .anytime:
                return "permissionAnytime"
            case .scheduled:
                return "permissionScheduled"
            }
        }
    }
}
