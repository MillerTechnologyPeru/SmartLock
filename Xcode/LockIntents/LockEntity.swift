//
//  LockEntity.swift
//  LockIntents
//
//  Created by Alsey Coleman Miller on 9/22/22.
//

import AppIntents
import LockKit

/// Lock Intent Entity
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
}

extension LockEntity {
    
    static var defaultQuery = LockQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Lock"
    }
    
    var displayRepresentation: DisplayRepresentation {
        let name: LocalizedStringResource
        if let key = FileManager.Lock.shared.applicationData?.locks[id] {
            name = "\(key.name)"
        } else {
            name = "Lock"
        }
        return DisplayRepresentation(
            title: name,
            subtitle: "UUID \(id.description) v\(version.description)",
            image: .init(systemName: "lock.fill")
        )
    }
}

extension LockEntity {
    
    init(information: LockInformation) {
        self.id = information.id
        self.buildVersion = information.buildVersion.rawValue
        self.version = information.version.rawValue
        self.status = information.status
        self.unlockActions = information.unlockActions
    }
}

extension LockStatus: AppEnum {
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Lock Status"
    }
    
    public static var caseDisplayRepresentations: [LockStatus : DisplayRepresentation] {
        [
            .setup: "Needs Setup",
            .unlock: "Ready to Unlock"
        ]
    }
}

extension UnlockAction: AppEnum {
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Unlock Action"
    }
    
    public static var caseDisplayRepresentations: [UnlockAction : DisplayRepresentation] {
        [
            .default: "Default",
            .button: "Button"
        ]
    }
}

