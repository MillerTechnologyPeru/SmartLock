//
//  NewKeyManagedObject.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/8/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public final class NewKeyManagedObject: NSManagedObject {
    
    internal convenience init(_ value: NewKey, lock: LockManagedObject, context: NSManagedObjectContext) {
        self.init(context: context)
        self.identifier = value.id
        self.update(value, lock: lock, context: context)
    }
    
    internal func update(_ value: NewKey, lock: LockManagedObject, context: NSManagedObjectContext) {
        self.lock = lock
        self.name = value.name
        self.created = value.created
        self.expiration = value.expiration
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

public extension NewKey {
    
    init?(managedObject: NewKeyManagedObject) {
        
        guard let id = managedObject.identifier,
            let name = managedObject.name,
            let created = managedObject.created,
            let permissionType = PermissionType(rawValue: numericCast(managedObject.permission)),
            let expiration = managedObject.expiration
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
            permission: permission,
            created: created,
            expiration: expiration
        )
    }
}

// MARK: - IdentifiableManagedObject

extension NewKeyManagedObject: IdentifiableManagedObject { }

// MARK: - Store

internal extension NSManagedObjectContext {
    
    @discardableResult
    func insert(_ newKey: NewKey, for lock: LockManagedObject) throws -> NewKeyManagedObject {
        
        if let managedObject = try find(id: newKey.id, type: NewKeyManagedObject.self) {
            assert(managedObject.lock == lock, "Key stored with conflicting lock")
            managedObject.update(newKey, lock: lock, context: self)
            return managedObject
        } else {
            return NewKeyManagedObject(newKey, lock: lock, context: self)
        }
    }
    
    @discardableResult
    func insert(_ key: NewKey, for lock: UUID) throws -> NewKeyManagedObject {
        
        let managedObject = try find(id: lock, type: LockManagedObject.self)
            ?? LockManagedObject(id: lock, name: "Lock", context: self)
        return try insert(key, for: managedObject)
    }
}
