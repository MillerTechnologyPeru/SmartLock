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
        /*
        let name: LocalizedStringResource
        if let key = FileManager.Lock.shared.applicationData?.locks[id] {
            name = "\(key.name)"
        } else {
            name = "Lock"
        }*/
        return DisplayRepresentation(
            title: "Lock",
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
        self.status = .init(rawValue: information.status.rawValue)!
        self.unlockActions = .init(information.unlockActions.map { .init(rawValue: $0.rawValue)! })
    }
}

enum LockStatus: UInt8, AppEnum {
    
    /// Initial Status
    case setup = 0x00
    
    /// Idle / Unlock Mode
    case unlock = 0x01
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Lock Status"
    }
    
    static var caseDisplayRepresentations: [LockStatus : DisplayRepresentation] {
        [
            .setup: "Needs Setup",
            .unlock: "Ready to Unlock"
        ]
    }
}

enum UnlockAction: UInt8, AppEnum {
    
    /// Unlock immediately.
    case `default` = 0b01
    
    /// Unlock when button is pressed.
    case button = 0b10
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Unlock Action"
    }
    
    static var caseDisplayRepresentations: [UnlockAction : DisplayRepresentation] {
        [
            .default: "Default",
            .button: "Button"
        ]
    }
}
