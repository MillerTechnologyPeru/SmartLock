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
    func removedKey(in context: NSManagedObjectContext) throws -> KeyManagedObject? {
        
        guard let key = self.key else {
            assertionFailure("Missing key value")
            return nil
        }
        
        guard let type = KeyType(rawValue: numericCast(self.type)) else {
            assertionFailure("Invalid key type")
            return nil
        }
        
        switch type {
        case .key:
            return try context.find(identifier: key, type: KeyManagedObject.self)
        case .newKey:
            return nil
        }
    }
}
