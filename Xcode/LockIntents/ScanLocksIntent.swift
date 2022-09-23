//
//  LockIntents.swift
//  LockIntents
//
//  Created by Alsey Coleman Miller on 9/22/22.
//

import AppIntents
import SwiftUI
import LockKit

struct ScanLocksIntent: AppIntent {
        
    static var title: LocalizedStringResource { "Scan for Locks" }
    
    static var description: IntentDescription {
        IntentDescription(
            "Scan for nearby locks",
            categoryName: "Utility",
            searchKeywords: ["scan", "bluetooth", "lock"]
        )
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Scan nearby locks for \(\.$duration) seconds")
    }
        
    @Parameter(
        title: "Duration",
        description: "Duration in seconds for scanning.",
        default: 1
    )
    var duration: TimeInterval
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let store = Store.shared
        do { try await store.central.waitPowerOn() }
        catch {
            return .result(
                value: [LockEntity](),
                view: view(for: [])
            )
        }
        try await store.scan(duration: duration)
        let locks = store.lockInformation
            .sorted(by: { $0.key.id.description < $1.key.id.description })
            .map { $0.value }
        return .result(
            value: locks.map { LockEntity(information: $0) },
            view: view(for: locks)
        )
    }
}

@MainActor
private extension ScanLocksIntent {
    
    func view(for results: [LockInformation]) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                if results.isEmpty {
                    Text("No locks found.")
                } else {
                    ForEach(results) {
                        view(for: $0)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
    
    func view(for lock: LockInformation) -> some View {
        /*
        let cache = Store.shared.applicationData.locks[lock.id]
        return VStack {
            Text(verbatim: cache?.name ?? (lock.status == .setup ? "Setup" : "Lock"))
            Text(verbatim: lock.id.description)
            if let permission = cache?.key.permission.type {
                Text(verbatim: permission.localizedText)
            }
        }*/
        if let cache = Store.shared.applicationData.locks[lock.id] {
            return LockRowView(
                image: .emoji("🔒"), //.permission(cache.key.permission.type),
                title: cache.name,
                subtitle: cache.key.permission.type.localizedText
            )
        } else {
            return LockRowView(
                image: .emoji("🔒"),
                title: lock.status == .setup ? "Setup" : "Lock",
                subtitle: lock.id.description
            )
        }
    }
}
