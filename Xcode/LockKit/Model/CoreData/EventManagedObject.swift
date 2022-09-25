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
import Predicate

public class EventManagedObject: NSManagedObject {
    
    @nonobjc public class var eventType: LockEvent.EventType { fatalError("Implemented by subclass") }
    
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
    
    public static func find(_ id: UUID, in context: NSManagedObjectContext) throws -> EventManagedObject? {
        
        try context.find(identifier: id as NSUUID,
                         propertyName: #keyPath(EventManagedObject.identifier),
                         type: EventManagedObject.self)
    }
}

internal extension LockEvent {
    
    init?(managedObject: EventManagedObject) {
        
        switch managedObject {
        case let eventManagedObject as SetupEventManagedObject:
            guard let event = Setup(managedObject: eventManagedObject)
                else { return nil }
            self = .setup(event)
        case let eventManagedObject as UnlockEventManagedObject:
            guard let event = Unlock(managedObject: eventManagedObject)
                else { return nil }
            self = .unlock(event)
        case let eventManagedObject as CreateNewKeyEventManagedObject:
            guard let event = CreateNewKey(managedObject: eventManagedObject)
                else { return nil }
            self = .createNewKey(event)
        case let eventManagedObject as ConfirmNewKeyEventManagedObject:
            guard let event = ConfirmNewKey(managedObject: eventManagedObject)
                else { return nil }
            self = .confirmNewKey(event)
        case let eventManagedObject as RemoveKeyEventManagedObject:
            guard let event = RemoveKey(managedObject: eventManagedObject)
                else { return nil }
            self = .removeKey(event)
        default:
            assertionFailure("Invalid \(managedObject)")
            return nil
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
        
        return try context.find(id: key, type: KeyManagedObject.self)
    }
}

public extension LockManagedObject {
    
    func lastEvent(in context: NSManagedObjectContext) throws -> EventManagedObject? {
        return try lastEvents(count: 1, in: context).first
    }
    
    func lastEvents(count: Int, in context: NSManagedObjectContext) throws -> [EventManagedObject] {
        
        let fetchRequest = NSFetchRequest<EventManagedObject>()
        fetchRequest.entity = EventManagedObject.entity()
        fetchRequest.fetchBatchSize = count
        fetchRequest.fetchLimit = count
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
        //let predicate = (.keyPath(#keyPath(EventManagedObject.lock.identifier)) == .value(self.identifier!))
        fetchRequest.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(EventManagedObject.lock),
            self
        )
        return try context.fetch(fetchRequest)
    }
}

// MARK: - Store

internal extension NSManagedObjectContext {
    
    @discardableResult
    func insert(_ events: [LockEvent], for lock: LockManagedObject) throws -> [EventManagedObject] {
        return try events.map {
            try insert($0, for: lock)
        }
    }
    
    @discardableResult
    func insert(_ event: LockEvent, for lock: LockManagedObject) throws -> EventManagedObject {
        try EventManagedObject.find(event.id, in: self)
            ?? EventManagedObject.initWith(event, lock: lock, context: self)
    }
    
    @discardableResult
    func insert(_ events: [LockEvent], for lock: UUID) throws -> [EventManagedObject] {
        let managedObject = try find(id: lock, type: LockManagedObject.self)
            ?? LockManagedObject(id: lock, name: "", context: self)
        return try insert(events, for: managedObject)
    }
    
    @discardableResult
    func insert(_ event: LockEvent, for lock: UUID) throws -> EventManagedObject {
        let managedObject = try find(id: lock, type: LockManagedObject.self)
            ?? LockManagedObject(id: lock, name: "", context: self)
        return try insert(event, for: managedObject)
    }
}
