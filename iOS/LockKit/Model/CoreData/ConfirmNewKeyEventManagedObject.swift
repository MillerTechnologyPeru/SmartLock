//
//  ConfirmNewKeyEventManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public final class ConfirmNewKeyEventManagedObject: EventManagedObject {
    
    @nonobjc override class var eventType: LockEvent.EventType { return .confirmNewKey }
    
    internal convenience init(_ value: LockEvent.ConfirmNewKey, lock: LockManagedObject, context: NSManagedObjectContext) {
        
        self.init(context: context)
        self.identifier = value.identifier
        self.lock = lock
        self.date = value.date
        self.key = value.key
        self.pendingKey = value.newKey
    }
}

// MARK: - IdentifiableManagedObject

extension ConfirmNewKeyEventManagedObject: IdentifiableManagedObject { }

// MARK: - Fetch

public extension ConfirmNewKeyEventManagedObject {
    
    /// Fetch the new key specified by the event.
    func newKey(in context: NSManagedObjectContext) throws -> NewKeyManagedObject? {
        
        guard let newKey = self.pendingKey else {
            assertionFailure("Missing key value")
            return nil
        }
        return try context.find(identifier: newKey, type: NewKeyManagedObject.self)
    }
    
    /// Fetch the removed key specified by the event.
    func createKeyEvent(in context: NSManagedObjectContext) throws -> CreateNewKeyEventManagedObject? {
        
        guard let newKey = self.pendingKey else {
            assertionFailure("Missing new key value")
            return nil
        }
        
        let fetchRequest = NSFetchRequest<CreateNewKeyEventManagedObject>()
        fetchRequest.entity = CreateNewKeyEventManagedObject.entity()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(CreateNewKeyEventManagedObject.pendingKey), newKey as NSUUID)
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        fetchRequest.returnsObjectsAsFaults = false
        return try context.fetch(fetchRequest).first
    }
}
