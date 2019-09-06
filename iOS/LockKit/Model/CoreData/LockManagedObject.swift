//
//  LockManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

public final class LockManagedObject: NSManagedObject {
    
    internal convenience init(identifier: UUID,
                              name: String,
                              information: LockCache.Information? = nil,
                              context: NSManagedObjectContext) {
        
        self.init(context: context)
        self.identifier = identifier
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

// MARK: - Store

internal extension NSManagedObjectContext {
    
    @discardableResult
    func insert(_ locks: [UUID: LockCache]) throws -> [LockManagedObject] {
        
        // insert locks
        locks.map { (identifier, cache) in
            
        }
        for (identifier, cache) in locks {
            // find or create managed object
            let lock: LockManagedObject
            if let managedObject = try find(identifier: identifier, type: LockManagedObject.self) {
                managedObject.name = cache.name
                managedObject.update(information: cache.information, context: self)
                lock = managedObject
            } else {
                lock = LockManagedObject(identifier: identifier,
                                         name: cache.name,
                                         information: cache.information,
                                         context: self)
            }

            // insert keys
            //let key = try insert(cache.key, for: lock)
            //assert((lock.keys ?? []).contains(key))
        }
    }
}
