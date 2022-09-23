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
        do {
            try await Store.shared.unlock(for: lock.id)
        }
        catch {
            return .result(
                value: false,
                content: { ResultView(error: error.localizedDescription) }
            )
        }
        return .result(
            value: true,
            content: { ResultView(error: nil) }
        )
    }
}


@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension UnlockIntent {
    
    struct ResultView: View {
        
        let error: String?
        
        var body: some View {
            VStack(alignment: .center, spacing: 8) {
                if let error = error {
                    Text("Unable to unlock")
                    Text(verbatim: error)
                } else {
                    Text("Unlocked")
                }
            }
        }
    }
}
