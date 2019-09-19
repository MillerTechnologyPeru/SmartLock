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
        guard let appGroupURL = FileManager.default.containerURL(for: .lock)
            else { fatalError("Couldn't get app group for \(AppGroup.lock.rawValue)") }
        let container = NSPersistentContainer(name: "LockCache", managedObjectModel: .lock)
        let storeDescription = NSPersistentStoreDescription(url: appGroupURL.appendingPathComponent("data.sqlite"))
        storeDescription.shouldInferMappingModelAutomatically = true
        storeDescription.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions = [storeDescription]
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
