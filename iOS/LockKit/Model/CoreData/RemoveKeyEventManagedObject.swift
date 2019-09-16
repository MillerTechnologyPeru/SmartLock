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
    
    @nonobjc override class var eventType: LockEvent.EventType { return .removeKey }
    
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

internal extension LockEvent.RemoveKey {
    
    init?(managedObject: RemoveKeyEventManagedObject) {
        
        guard let identifier = managedObject.identifier,
            let date = managedObject.date,
            let key = managedObject.key,
            let removedKey = managedObject.removedKey,
            let type = KeyType(rawValue: numericCast(managedObject.type))
            else { return nil }
        
        self.init(identifier: identifier, date: date, key: key, removedKey: removedKey, type: type)
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
