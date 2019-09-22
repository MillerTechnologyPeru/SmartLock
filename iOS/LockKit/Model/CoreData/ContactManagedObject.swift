//
//  ContactManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public final class ContactManagedObject: NSManagedObject {
    
    internal convenience init(cloudRecord: String, context: NSManagedObjectContext) {
        
        self.init(context: context)
        self.cloudRecord = cloudRecord
    }
}

// MARK: - Fetch

public extension ContactManagedObject {
    
    static func fetch(in context: NSManagedObjectContext) throws -> [ContactManagedObject] {
        let fetchRequest = NSFetchRequest<ContactManagedObject>()
        fetchRequest.entity = entity()
        fetchRequest.fetchBatchSize = 30
        fetchRequest.sortDescriptors = [
            .init(keyPath: \ContactManagedObject.cloudRecord, ascending: true)
        ]
        return try context.fetch(fetchRequest)
    }
}
