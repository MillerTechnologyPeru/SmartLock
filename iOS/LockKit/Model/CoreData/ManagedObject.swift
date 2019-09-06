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
    func performErrorBlockAndWait(_ block: @escaping () throws -> ()) throws {
        
        var blockError: Swift.Error?
        
        performAndWait {
            do { try block() }
            catch { blockError = error }
            return
        }
        
        if let error = blockError {
            throw error
        }
    }
}

public protocol IdentifiableManagedObject {
    
    var identifier: UUID? { get }
}

public extension NSManagedObjectContext {
    
    func find<T>(identifier: UUID, type: T.Type) throws -> T? where T: IdentifiableManagedObject, T: NSManagedObject {
        
        let fetchRequest = NSFetchRequest<T>()
        fetchRequest.entity = T.entity()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", "identifier", identifier as NSUUID)
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = true
        fetchRequest.returnsObjectsAsFaults = false
        return try self.fetch(fetchRequest).first
    }
}
