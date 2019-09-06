//
//  ManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/5/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

internal extension NSManagedObjectContext {
    
    /// Wraps the block to allow for error throwing.
    func performErrorBlockAndWait(_ block: @escaping () throws -> ()) throws {
        
        var blockError: Swift.Error?
        
        self.performAndWait {
            do { try block() }
            catch { blockError = error }
            return
        }
        
        if let error = blockError {
            throw error
        }
        
        return
    }
    
    func find<T: NSManagedObject>(identifier: NSObject, property: String, entityName: String) throws -> T? {
        
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", property, identifier)
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = true
        fetchRequest.returnsObjectsAsFaults = false
        return try self.fetch(fetchRequest).first
    }
    
    func findOrCreate<T: NSManagedObject>(identifier: NSObject, property: String, entityName: String) throws -> T {
        
        if let existing: T = try self.find(identifier: identifier, property: property, entityName: entityName) {
            
            return existing
            
        } else {
            
            // create a new entity
            let newManagedObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self) as! T
            
            // set resource ID
            newManagedObject.setValue(identifier, forKey: property)
            
            return newManagedObject
        }
    }
}

internal protocol IdentifiableManagedObject {
    
    associatedtype ManagedObject: NSManagedObject
    
    static func fetchRequest() -> NSFetchRequest<ManagedObject>
    
    var identifier: UUID? { get }
}

internal extension NSManagedObjectContext {
    
    func find<T>(identifier: UUID, type: T.Type) throws -> T.ManagedObject? where T: IdentifiableManagedObject {
        
        let fetchRequest = T.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", "identifier", identifier as NSUUID)
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = true
        fetchRequest.returnsObjectsAsFaults = false
        return try self.fetch(fetchRequest).first
    }
}
