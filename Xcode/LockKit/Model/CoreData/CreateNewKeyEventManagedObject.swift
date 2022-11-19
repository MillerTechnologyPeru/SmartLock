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
import Predicate

public final class CreateNewKeyEventManagedObject: EventManagedObject {
    
    @nonobjc override public class var eventType: LockEvent.EventType { return .createNewKey }
    
    internal convenience init(_ value: LockEvent.CreateNewKey, lock: LockManagedObject, context: NSManagedObjectContext) {
        
        self.init(context: context)
        self.identifier = value.id
        self.lock = lock
        self.date = value.date
        self.key = value.key
        self.pendingKey = value.newKey
    }
}

public extension LockEvent.CreateNewKey {
    
    init?(managedObject: CreateNewKeyEventManagedObject) {
        
        guard let id = managedObject.identifier,
            let date = managedObject.date,
            let key = managedObject.key,
            let pendingKey = managedObject.pendingKey
            else { return nil }
        
        self.init(id: id, date: date, key: key, newKey: pendingKey)
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
        return try context.find(id: newKey, type: NewKeyManagedObject.self)
    }
    
    func confirmKeyEvent(in context: NSManagedObjectContext) throws -> ConfirmNewKeyEventManagedObject? {
        
        guard let newKey = self.pendingKey else {
            assertionFailure("Missing new key value")
            return nil
        }
        
        let fetchRequest = NSFetchRequest<ConfirmNewKeyEventManagedObject>()
        fetchRequest.entity = ConfirmNewKeyEventManagedObject.entity()
        let predicate = (.keyPath(#keyPath(ConfirmNewKeyEventManagedObject.pendingKey)) == .value(.uuid(newKey))).toFoundation()
        assert(predicate == NSPredicate(format: "%K == %@", #keyPath(ConfirmNewKeyEventManagedObject.pendingKey), newKey as NSUUID))
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        fetchRequest.returnsObjectsAsFaults = false
        return try context.fetch(fetchRequest).first
    }
}
