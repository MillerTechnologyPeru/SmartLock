//
//  CreateNewKeyEventManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public final class CreateNewKeyEventManagedObject: EventManagedObject {
    
    @nonobjc override class var eventType: LockEvent.EventType { return .createNewKey }
    
    internal convenience init(_ value: LockEvent.CreateNewKey, lock: LockManagedObject, context: NSManagedObjectContext) {
        
        self.init(context: context)
        self.identifier = value.identifier
        self.lock = lock
        self.date = value.date
        self.key = value.key
        self.pendingKey = value.newKey
    }
}

// MARK: - IdentifiableManagedObject

extension CreateNewKeyEventManagedObject: IdentifiableManagedObject { }

// MARK: - Fetch

public extension CreateNewKeyEventManagedObject {
    
    /// Fetch the new key specified by the event.
    func newKey(in context: NSManagedObjectContext) throws -> NewKeyManagedObject? {
        
        guard let newKey = self.pendingKey else {
            assertionFailure("Missing key value")
            return nil
        }
        return try context.find(identifier: newKey, type: NewKeyManagedObject.self)
    }
    
    func confirmKeyEvent(in context: NSManagedObjectContext) throws -> ConfirmNewKeyEventManagedObject? {
        
        guard let newKey = self.pendingKey else {
            assertionFailure("Missing new key value")
            return nil
        }
        
        let fetchRequest = NSFetchRequest<ConfirmNewKeyEventManagedObject>()
        fetchRequest.entity = ConfirmNewKeyEventManagedObject.entity()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(ConfirmNewKeyEventManagedObject.pendingKey), newKey as NSUUID)
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        fetchRequest.returnsObjectsAsFaults = false
        return try context.fetch(fetchRequest).first
    }
}
