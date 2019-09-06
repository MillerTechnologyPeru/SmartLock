//
//  EventManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public class EventManagedObject: NSManagedObject {
    
    internal static func `init`(_ value: LockEvent, lock: LockManagedObject, context: NSManagedObjectContext) -> EventManagedObject {
                
        switch value {
        case let .setup(event):
            return SetupEventManagedObject(event, lock: lock, context: context)
        case let .unlock(event):
            return UnlockEventManagedObject(event, lock: lock, context: context)
        case let .createNewKey(event):
            return CreateNewKeyEventManagedObject(event, lock: lock, context: context)
        case let .confirmNewKey(event):
            return ConfirmNewKeyEventManagedObject(event, lock: lock, context: context)
        case let .removeKey(event):
            return RemoveKeyEventManagedObject(event, lock: lock, context: context)
        }
    }
}

// MARK: - Fetch

public extension EventManagedObject {
    
    /// Fetch the key specified by the event.
    func key(in context: NSManagedObjectContext) throws -> KeyManagedObject? {
        
        guard let key = self.key else {
            assertionFailure("Missing key value")
            return nil
        }
        
        return try context.find(identifier: key, type: KeyManagedObject.self)
    }
}
