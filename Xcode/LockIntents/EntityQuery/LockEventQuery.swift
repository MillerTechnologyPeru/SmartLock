//
//  LockEventQuery.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/24/22.
//

import Foundation
import CoreData
import AppIntents
import LockKit

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
struct LockEventQuery: EntityQuery {
    
    func entities(for identifiers: [UUID]) async throws -> [LockEventEntity] {
        let context = await Store.shared.backgroundContext
        return try await context.perform {
            return try identifiers
                .lazy
                .compactMap { try EventManagedObject.find($0, in: context) }
                .compactMap { .init(managedObject: $0) }
        }
    }
    
    func suggestedEntities() async throws -> [LockEventEntity] {
        let eventsSuggested = 3
        let context = await Store.shared.backgroundContext
        return try await context.perform {
            let locks = try LockManagedObject.fetch(in: context)
            var events = [EventManagedObject]()
            events.reserveCapacity(locks.count * eventsSuggested)
            for lock in locks {
                events += try lock.lastEvents(count: eventsSuggested, in: context)
            }
            return events.compactMap { .init(managedObject: $0) }
        }
    }
}
