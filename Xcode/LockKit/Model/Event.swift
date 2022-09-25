//
//  Event.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/8/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public extension LockEvent.EventType {
    
    var symbol: Character {
        switch self {
        case .setup:
            return "🔐"
        case .unlock:
            return "🔓"
        case .createNewKey:
            return "🔏"
        case .confirmNewKey:
            return "🔑"
        case .removeKey:
            return "🗑"
        }
    }
}

public extension EventManagedObject {
    
    func displayRepresentation(
        displayLockName: Bool,
        in context: NSManagedObjectContext
    ) throws -> (title: String, subtitle: String, needsKeys: Set<UUID>) {
        var needsKeys = Set<UUID>()
        guard let lock = self.lock?.identifier else {
            fatalError("Missing lock identifier")
        }
        let eventType = type(of: self).eventType
        let action: String
        var keyName: String
        let key = try self.key(in: context)
        if key == nil {
            needsKeys.insert(lock)
        }
        switch self {
        case is SetupEventManagedObject:
            action = "Setup" //R.string.locksEventsViewController.eventsSetup()
            keyName = key?.name ?? ""
        case is UnlockEventManagedObject:
            action = "Unlocked" //R.string.locksEventsViewController.eventsUnlocked()
            keyName = key?.name ?? ""
        case let event as CreateNewKeyEventManagedObject:
            if let newKey = try event.confirmKeyEvent(in: context)?.key(in: context)?.name {
                action = "Shared \(newKey)" //R.string.locksEventsViewController.eventsSharedNamed(newKey)
            } else if let newKey = try event.newKey(in: context)?.name {
                action = "Shared \(newKey)" //R.string.locksEventsViewController.eventsSharedNamed(newKey)
            } else {
                action = "Shared key" //R.string.locksEventsViewController.eventsShared()
                needsKeys.insert(lock)
            }
            keyName = key?.name ?? ""
        case let event as ConfirmNewKeyEventManagedObject:
            if let key = key,
                let permission = PermissionType(rawValue: numericCast(key.permission)) {
                action = "Recieved \(permission.localizedText) from \(key.name ?? "")" //R.string.locksEventsViewController.eventsCreated(key.name ?? "", permission.localizedText)
                if let parentKey = try! event.createKeyEvent(in: context)?.key(in: context) {
                    keyName = "Shared by \(parentKey.name ?? "")" //R.string.locksEventsViewController.eventsSharedBy(parentKey.name ?? "")
                } else {
                    keyName = ""
                    needsKeys.insert(lock)
                }
            } else {
                action = "Created key" //R.string.locksEventsViewController.eventsCreatedNamed()
                keyName = ""
                needsKeys.insert(lock)
            }
        case let event as RemoveKeyEventManagedObject:
            if let removedKey = try event.removedKey(in: context)?.name {
                action = "Removed key \(removedKey)" //R.string.locksEventsViewController.eventsRemovedNamed(removedKey)
            } else {
                action = "Removed key" //R.string.locksEventsViewController.eventsRemoved()
                needsKeys.insert(lock)
            }
            keyName = key?.name ?? ""
        default:
            fatalError("Invalid event \(self)")
        }
        
        let lockName = self.lock?.name ?? ""
        if displayLockName, // if filtering for a single lock
           lockName.isEmpty == false {
            keyName = keyName.isEmpty ? lockName : lockName + " - " + keyName
        }
        return (action, keyName, needsKeys)
    }
}
