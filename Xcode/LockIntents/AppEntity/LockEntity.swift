//
//  LockEntity.swift
//  LockIntents
//
//  Created by Alsey Coleman Miller on 9/22/22.
//

import AppIntents
import LockKit

/// Lock Intent Entity
@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
struct LockEntity: AppEntity, Identifiable {
    
    let id: UUID
    
    /// Firmware build number
    var buildVersion: UInt64
    
    /// Firmware version
    var version: String
    
    /// Device state
    var status: LockStatus
    
    /// Supported lock actions
    var unlockActions: Set<UnlockAction>
    
    /// Stored name
    var name: String?
    
    /// Associated key
    var key: KeyEntity?
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension LockEntity {
    
    static var defaultQuery = LockQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Lock"
    }
    
    var displayRepresentation: DisplayRepresentation {
        let permission = self.key?.permission ?? .anytime
        return DisplayRepresentation(
            title: "\(name ?? "Lock")",
            subtitle: "\(id.description)",
            image: .init(named: permission.imageName, isTemplate: false)
        )
    }
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
private extension LockEntity {
    
    var image: PermissionType.Image {
        PermissionType.Image(permissionType: .init(rawValue: (key?.permission ?? .anytime).rawValue)!)
    }
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension LockEntity {
    
    init(information: LockInformation, name: String?, key: KeyEntity?) {
        self.id = information.id
        self.buildVersion = information.buildVersion.rawValue
        self.version = information.version.rawValue
        self.status = .init(rawValue: information.status.rawValue)!
        self.unlockActions = .init(information.unlockActions.map { .init(rawValue: $0.rawValue)! })
        self.name = name
        self.key = key
    }
}
