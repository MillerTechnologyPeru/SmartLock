//
//  ManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/5/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

public extension NSManagedObjectModel {
    
    static var lock: NSManagedObjectModel {
        guard let url = Bundle.lockKit.url(forResource: "Model", withExtension: "momd")
            else { fatalError("No url for model") }
        guard let model = NSManagedObjectModel(contentsOf: url)
            else { fatalError("No model at \(url.path)") }
        return model
    }
}

internal extension NSManagedObjectContext {
    
    /// Wraps the block to allow for error throwing.
    func performErrorBlockAndWait<T>(_ block: @escaping () throws -> (T)) throws -> T {
        
        var blockError: Swift.Error?
        var value: T!
        performAndWait {
            do { value = try block() }
            catch { blockError = error }
            return
        }
        
        if let error = blockError {
            throw error
        }
        return value
    }
    
    func commit(_ block: @escaping (NSManagedObjectContext) throws -> ()) {
        
        assert(concurrencyType == .privateQueueConcurrencyType)
        perform { [unowned self] in
            self.reset()
            do {
                try block(self)
                if self.hasChanges {
                    try self.save()
                }
            } catch {
                log("⚠️ Unable to commit changes: \(error.localizedDescription)")
                #if DEBUG
                print(error)
                #endif
                assertionFailure("Core Data error")
                return
            }
        }
    }
    
    func commit(_ block: @escaping (NSManagedObjectContext) throws -> ()) async {
        
        assert(concurrencyType == .privateQueueConcurrencyType)
        await perform { [unowned self] in
            self.reset()
            do {
                try block(self)
                if self.hasChanges {
                    try self.save()
                }
            } catch {
                log("⚠️ Unable to commit changes: \(error.localizedDescription)")
                #if DEBUG
                print(error)
                #endif
                assertionFailure("Core Data error")
                return
            }
        }
    }
}

internal extension NSManagedObjectContext {
    
    func find<T>(identifier: NSObject, propertyName: String, type: T.Type) throws -> T? where T: NSManagedObject {
        
        let fetchRequest = NSFetchRequest<T>()
        fetchRequest.entity = T.entity()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", propertyName, identifier)
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = true
        fetchRequest.returnsObjectsAsFaults = false
        return try self.fetch(fetchRequest).first
    }
}

public protocol IdentifiableManagedObject {
    
    var identifier: UUID? { get }
}

public extension NSManagedObjectContext {
    
    func find<T>(id: UUID, type: T.Type) throws -> T? where T: IdentifiableManagedObject, T: NSManagedObject {
        
        let fetchRequest = NSFetchRequest<T>()
        fetchRequest.entity = T.entity()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", "identifier", id as NSUUID)
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = true
        fetchRequest.returnsObjectsAsFaults = false
        return try self.fetch(fetchRequest).first
    }
}
