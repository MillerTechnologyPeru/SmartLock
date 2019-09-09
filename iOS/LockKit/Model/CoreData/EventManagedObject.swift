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
    
    @nonobjc class var eventType: LockEvent.EventType { fatalError("Implemented by subclass") }
    
    internal static func initWith(_ value: LockEvent, lock: LockManagedObject, context: NSManagedObjectContext) -> EventManagedObject {
                
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
    
    internal static func find(_ identifier: UUID, in context: NSManagedObjectContext) throws -> EventManagedObject? {
        
        try context.find(identifier: identifier as NSUUID,
                         propertyName: #keyPath(EventManagedObject.identifier),
                         type: EventManagedObject.self)
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

public extension LockManagedObject {
    
    func lastEvent(in context: NSManagedObjectContext) throws -> EventManagedObject? {
        
        let fetchRequest = NSFetchRequest<EventManagedObject>()
        fetchRequest.entity = EventManagedObject.entity()
        fetchRequest.fetchBatchSize = 10
        fetchRequest.includesSubentities = true
        fetchRequest.shouldRefreshRefetchedObjects = false
        fetchRequest.returnsObjectsAsFaults = true
        fetchRequest.includesPropertyValues = false
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(
                key: #keyPath(EventManagedObject.date),
                ascending: false
            )
        ]
        fetchRequest.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(EventManagedObject.lock),
            self
        )
        return try context.fetch(fetchRequest).first
    }
}

// MARK: - Store

internal extension NSManagedObjectContext {
    
    @discardableResult
    func insert(_ events: [LockEvent], for lock: LockManagedObject) throws -> [EventManagedObject] {
        
        // insert events
        return try events.map {
            try EventManagedObject.find($0.identifier, in: self)
                ?? EventManagedObject.initWith($0, lock: lock, context: self)
        }
    }
    
    @discardableResult
    func insert(_ events: [LockEvent], for lock: UUID) throws -> [EventManagedObject] {
        
        let managedObject = try find(identifier: lock, type: LockManagedObject.self)
            ?? LockManagedObject(identifier: lock, name: "", context: self)
        return try insert(events, for: managedObject)
    }
}
