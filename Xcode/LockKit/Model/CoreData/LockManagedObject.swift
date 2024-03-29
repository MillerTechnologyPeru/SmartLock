//
//  LockManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock
import Predicate

public final class LockManagedObject: NSManagedObject {
    
    internal convenience init(id: UUID,
                              name: String,
                              information: LockCache.Information? = nil,
                              context: NSManagedObjectContext) {
        
        self.init(context: context)
        self.identifier = id
        self.name = name
        if let information = information {
            update(information: information, context: context)
        }
    }
}

internal extension LockManagedObject {
    
    func update(information: LockCache.Information, context: NSManagedObjectContext) {
        
        if let managedObject = self.information {
            managedObject.update(information)
        } else {
            self.information = LockInformationManagedObject(information, context: context)
        }
    }
}

// MARK: - IdentifiableManagedObject

extension LockManagedObject: IdentifiableManagedObject { }

// MARK: - Fetch

public extension LockManagedObject {
    
    static func fetch(in context: NSManagedObjectContext, sort: [NSSortDescriptor] = []) throws -> [LockManagedObject] {
        let fetchRequest = NSFetchRequest<LockManagedObject>()
        fetchRequest.entity = entity()
        fetchRequest.fetchBatchSize = 10
        fetchRequest.sortDescriptors = sort.isEmpty == false ? sort : [
            .init(keyPath: \LockManagedObject.identifier, ascending: true)
        ]
        return try context.fetch(fetchRequest)
    }
    
    static func fetch(
        for identifiers: [UUID],
        in context: NSManagedObjectContext,
        sort: [NSSortDescriptor] = []
    ) throws -> [LockManagedObject] {
        let fetchRequest = LockManagedObject.fetchRequest()
        let predicate = #keyPath(LockManagedObject.identifier).in(identifiers)
        fetchRequest.predicate = predicate.toFoundation()
        assert(fetchRequest.predicate?.description == predicate.description)
        fetchRequest.fetchBatchSize = identifiers.count
        fetchRequest.fetchLimit = identifiers.count
        fetchRequest.sortDescriptors = sort.isEmpty == false ? sort : [
            .init(keyPath: \LockManagedObject.identifier, ascending: true)
        ]
        return try context.fetch(fetchRequest)
    }
}

// MARK: - Store

internal extension NSManagedObjectContext {
    
    @discardableResult
    func insert(_ locks: [UUID: LockCache]) throws -> [LockManagedObject] {
        
        // insert locks
        return try locks.map { (identifier, cache) in
            if let managedObject = try find(id: identifier, type: LockManagedObject.self) {
                // update name
                managedObject.name = cache.name
                // update read info
                managedObject.update(information: cache.information, context: self)
                // insert key
                try insert(cache.key, for: managedObject)
                return managedObject
            } else {
                return LockManagedObject(id: identifier,
                                         name: cache.name,
                                         information: cache.information,
                                         context: self)
            }
        }
    }
    
    @discardableResult
    func insert(_ cloudValue: CloudLock) throws -> LockManagedObject {
        
        // insert lock
        let lockManagedObject: LockManagedObject
        if let managedObject = try find(id: cloudValue.id.rawValue, type: LockManagedObject.self) {
            managedObject.name = cloudValue.name
            lockManagedObject = managedObject
        } else {
            lockManagedObject = LockManagedObject(id: cloudValue.id.rawValue,
                                                  name: cloudValue.name,
                                                  context: self)
        }
        return lockManagedObject
    }
}
