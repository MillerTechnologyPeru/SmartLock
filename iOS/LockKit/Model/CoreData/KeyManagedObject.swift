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
        self.identifier = value.identifier
        self.lock = lock
        self.name = value.name
        self.created = value.created
        self.permission = numericCast(value.permission.type.rawValue)
        if case let .scheduled(schedule) = value.permission {
            self.schedule = .init(schedule, context: context)
        }
    }
}

public extension Key {
    
    init?(managedObject: KeyManagedObject) {
        
        guard let identifier = managedObject.identifier,
            let name = managedObject.name,
            let created = managedObject.created,
            let permissionType = PermissionType(rawValue: numericCast(managedObject.permission))
            else { return nil }
        
        let permission: Permission
        switch permissionType {
        case .owner:
            permission = .owner
        case .admin:
            permission = .owner
        case .anytime:
            permission = .anytime
        case .scheduled:
            guard let schedule = managedObject.schedule.flatMap({ Permission.Schedule(managedObject: $0) })
                else { return nil }
            permission = .scheduled(schedule)
        }
        
        self.init(
            identifier: identifier,
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
        
        if let managedObject = try find(identifier: key.identifier, type: KeyManagedObject.self) {
            assert(managedObject.lock == lock, "Key stored with conflicting lock")
            return managedObject
        } else {
            return KeyManagedObject(key, lock: lock, context: self)
        }
    }
    
    @discardableResult
    func insert(_ key: Key, for lock: UUID) throws -> KeyManagedObject {
        
        let managedObject = try find(identifier: lock, type: LockManagedObject.self)
            ?? LockManagedObject(identifier: lock, name: "", context: self)
        return try insert(key, for: managedObject)
    }
}
