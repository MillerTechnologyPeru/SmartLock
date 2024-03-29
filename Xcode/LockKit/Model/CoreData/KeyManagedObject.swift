//
//  KeyManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public final class KeyManagedObject: NSManagedObject {
    
    internal convenience init(_ value: Key, lock: LockManagedObject, context: NSManagedObjectContext) {
        self.init(context: context)
        self.identifier = value.id
        self.update(value, lock: lock, context: context)
    }
    
    internal func update(_ value: Key, lock: LockManagedObject, context: NSManagedObjectContext) {
        self.lock = lock
        self.name = value.name
        self.created = value.created
        self.permission = numericCast(value.permission.type.rawValue)
        if case let .scheduled(schedule) = value.permission {
            if let _ = self.schedule {
                // don't update
            } else {
                self.schedule = .init(schedule, context: context)
            }
        }
    }
}

public extension Key {
    
    init?(managedObject: KeyManagedObject) {
        
        guard let id = managedObject.identifier,
            let name = managedObject.name,
            let created = managedObject.created,
            let permissionType = PermissionType(rawValue: numericCast(managedObject.permission))
            else { return nil }
        
        let permission: Permission
        switch permissionType {
        case .owner:
            permission = .owner
        case .admin:
            permission = .admin
        case .anytime:
            permission = .anytime
        case .scheduled:
            guard let schedule = managedObject.schedule.flatMap({ Permission.Schedule(managedObject: $0) })
                else { return nil }
            permission = .scheduled(schedule)
        }
        
        self.init(
            id: id,
            name: name,
            created: created,
            permission: permission
        )
    }
}

// MARK: - IdentifiableManagedObject

extension KeyManagedObject: IdentifiableManagedObject { }

// MARK: - Store

internal extension NSManagedObjectContext {
    
    @discardableResult
    func insert(_ key: Key, for lock: LockManagedObject) throws -> KeyManagedObject {
        
        if let managedObject = try find(id: key.id, type: KeyManagedObject.self) {
            assert(managedObject.lock == lock, "Key stored with conflicting lock")
            managedObject.update(key, lock: lock, context: self)
            return managedObject
        } else {
            return KeyManagedObject(key, lock: lock, context: self)
        }
    }
    
    @discardableResult
    func insert(_ key: Key, for lock: UUID) throws -> KeyManagedObject {
        
        let managedObject = try find(id: lock, type: LockManagedObject.self)
            ?? LockManagedObject(id: lock, name: "", context: self)
        return try insert(key, for: managedObject)
    }
    
    @discardableResult
    func insert(_ key: KeyListNotification.KeyValue, for lock: UUID) throws -> NSManagedObject {
        switch key {
        case let .key(key):
            return try insert(key, for: lock)
        case let .newKey(key):
            return try insert(key, for: lock)
        }
    }
}
