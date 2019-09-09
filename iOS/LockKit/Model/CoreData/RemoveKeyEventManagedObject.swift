//
//  RemoveKeyEventManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public final class RemoveKeyEventManagedObject: EventManagedObject {
    
    internal convenience init(_ value: LockEvent.RemoveKey, lock: LockManagedObject, context: NSManagedObjectContext) {
        
        self.init(context: context)
        self.identifier = value.identifier
        self.lock = lock
        self.date = value.date
        self.key = value.key
        self.removedKey = value.removedKey
        self.type = numericCast(value.type.rawValue)
    }
}

// MARK: - IdentifiableManagedObject

extension RemoveKeyEventManagedObject: IdentifiableManagedObject { }

// MARK: - Fetch

public extension RemoveKeyEventManagedObject {
    
    /// Fetch the removed key specified by the event.
    func removedKey(in context: NSManagedObjectContext) throws -> RemovedKey? {
        
        guard let removedKey = self.removedKey else {
            assertionFailure("Missing key value")
            return nil
        }
        
        guard let type = KeyType(rawValue: numericCast(self.type)) else {
            assertionFailure("Invalid key type")
            return nil
        }
        
        switch type {
        case .key:
            guard let managedObject = try context.find(identifier: removedKey, type: KeyManagedObject.self)
                else { return nil }
            return .key(managedObject)
        case .newKey:
            guard let managedObject = try context.find(identifier: removedKey, type: NewKeyManagedObject.self)
                else { return nil }
            return .newKey(managedObject)
        }
    }
}

// MARK: - Supporting Types

public extension RemoveKeyEventManagedObject {
    
    enum RemovedKey {
        case key(KeyManagedObject)
        case newKey(NewKeyManagedObject)
    }
}

public extension RemoveKeyEventManagedObject.RemovedKey {
    
    var identifier: UUID? {
        switch self {
        case let .key(managedObject): return managedObject.identifier
        case let .newKey(managedObject): return managedObject.identifier
        }
    }
    
    var name: String? {
        switch self {
        case let .key(managedObject): return managedObject.name
        case let .newKey(managedObject): return managedObject.name
        }
    }
}
