//
//  FetchEventsIntent.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/23/22.
//

import AppIntents
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
    
    static var parameterSummary: some ParameterSummary {
        Summary("Fetch the events for \(\.$lock)")
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
        description: "The fetch limit of the fetch request."
    )
    var limit: Int?
    
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
        let fetchRequest = LockEvent.FetchRequest(
            offset: UInt8(offset),
            limit: limit.flatMap(UInt8.init),
            predicate: .init(
                keys: keys.map { $0.id },
                start: start,
                end: end
            )
        )
        // search for lock if not in cache
        guard let peripheral = try await store.device(for: lock.id) else {
            throw LockError.notInRange(lock: lock.id)
        }
        // fetch events
        let events = try await Store.shared.listEvents(
            for: peripheral,
            fetchRequest: fetchRequest
        )
        return .result(
            value: "\(events)"
        )
    }
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension FetchEventsIntent {
    
    
}
