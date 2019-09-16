//
//  PersistentStore.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/8/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

public extension NSPersistentContainer {
    
    static var lock: NSPersistentContainer {
        let container = NSPersistentContainer(name: "LockCache", managedObjectModel: .lock)
        return container
    }
}

internal extension NSPersistentContainer {
    
    func commit(_ block: @escaping (NSManagedObjectContext) throws -> ()) {
        
        performBackgroundTask {
            do {
                try block($0)
                if $0.hasChanges {
                    try $0.save()
                }
            } catch {
                log("⚠️ Unable to commit changes: \(error.localizedDescription)")
                #if DEBUG
                dump(error)
                #endif
                assertionFailure("Core Data error")
                return
            }
        }
    }
}
