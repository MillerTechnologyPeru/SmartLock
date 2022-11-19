//
//  FetchEventsIntent.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/23/22.
//

import Foundation
import AppIntents
import CoreData
import SwiftUI
import LockKit

/// Intent for fetching events
@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
struct FetchEventsIntent: AppIntent {
    
    static var title: LocalizedStringResource { "Fetch Events" }
    
    static var description: IntentDescription {
        IntentDescription(
            "Fetch the events for a specified lock.",
            categoryName: "Utility",
            searchKeywords: ["events", "bluetooth", "lock"]
        )
    }
    
    /// The specified lock to unlock.
    @Parameter(
        title: "Lock",
        description: "The specified lock to fetch events from."
    )
    var lock: LockEntity
    
    /// The fetch offset of the fetch request.
    @Parameter(
        title: "Offset",
        description: "The fetch offset of the fetch request.",
        default: 0
    )
    var offset: Int
    
    /// The fetch limit of the fetch request.
    @Parameter(
        title: "Limit",
        description: "The fetch limit of the fetch request.",
        default: 10
    )
    var limit: Int
    
    /// The keys used to filter the results.
    @Parameter(
        title: "Keys",
        description: "The keys used to filter the results.",
        default: []
    )
    var keys: [KeyEntity]
    
    /// The start date to filter results.
    @Parameter(
        title: "Start",
        description: "The start date to filter results."
    )
    var start: Date?
    
    /// The end date to filter results.
    @Parameter(
        title: "End",
        description: "The end date to filter results."
    )
    var end: Date?
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let store = Store.shared
        // search for lock if not in cache
        guard let peripheral = try await store.device(for: lock.id) else {
            throw LockError.notInRange(lock: lock.id)
        }
        // fetch events
        let events = try await store.listEvents(
            for: peripheral,
            fetchRequest: fetchRequest
        )
        let managedObjectContext = Store.shared.managedObjectContext
        let managedObjects = try events.compactMap { try EventManagedObject.find($0.id, in: managedObjectContext) }
        assert(managedObjects.count == events.count)
        return .result(
            value: events.map { LockEventEntity($0, lock: lock.id) },
            view: view(for: managedObjects, in: managedObjectContext)
        )
    }
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
@MainActor
private extension FetchEventsIntent {
    
    var fetchRequest: LockEvent.FetchRequest {
        LockEvent.FetchRequest(
            offset: UInt8(offset),
            limit: UInt8(min(self.limit, Int(UInt8.max))),
            predicate: .init(
                keys: keys.map { $0.id },
                start: start,
                end: end
            )
        )
    }
    
    func view(for results: [EventManagedObject], in managedObjectContext: NSManagedObjectContext) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                if results.isEmpty {
                    Text("No events found.")
                        .padding(20)
                } else {
                    if results.count > 3 {
                        Text("Found \(results.count) events.")
                            .padding(20)
                    } else {
                        ForEach(results) {
                            view(for: $0, in: managedObjectContext)
                                .padding(8)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
    
    func view(for managedObject: EventManagedObject, in managedObjectContext: NSManagedObjectContext) -> some View {
        let eventType = type(of: managedObject).eventType
        let (action, keyName, _) = try! managedObject.displayRepresentation(
            displayLockName: true,
            in: managedObjectContext
        )
        #if os(watchOS)
        return LockRowView(
            image: .emoji(eventType.symbol),
            title: action,
            subtitle: keyName + "\n" + (managedObject.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
        )
        #else
        return LockRowView(
            image: .emoji(eventType.symbol),
            title: action,
            subtitle: keyName,
            trailing: (
                managedObject.date?.formatted(date: .numeric, time: .omitted) ?? "",
                managedObject.date?.formatted(date: .omitted, time: .shortened) ?? ""
            )
        )
        #endif
    }
}
