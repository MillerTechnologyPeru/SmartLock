//
//  UnlockIntent.swift
//  LockIntents
//
//  Created by Alsey Coleman Miller on 9/22/22.
//

import AppIntents
import SwiftUI
import LockKit

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
struct UnlockIntent: AppIntent {
    
    static var title: LocalizedStringResource { "Unlock" }
    
    static var description: IntentDescription {
        IntentDescription(
            "Unlock a door.",
            categoryName: "Utility",
            searchKeywords: ["unlock", "bluetooth", "lock"]
        )
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Unlocks \(\.$lock)")
    }
    
    @Parameter(
        title: "Lock",
        description: "The specified lock to unlock."
    )
    var lock: LockEntity
    
    @MainActor
    func perform() async throws -> some IntentResult {
        try await Store.shared.unlock(for: lock.id)
        return .result()
    }
}
