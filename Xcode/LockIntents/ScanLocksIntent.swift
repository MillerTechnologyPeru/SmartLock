//
//  LockIntents.swift
//  LockIntents
//
//  Created by Alsey Coleman Miller on 9/22/22.
//

import AppIntents
import LockKit

struct ScanLocksIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Scan for Locks"
    
    @Parameter(title: "Duration", default: 1)
    var duration: TimeInterval
    
    func perform() async throws -> some IntentResult {
        let store = await Store.shared
        try await store.scan(duration: duration)
        let locks = await store.lockInformation
            .lazy
            .sorted(by: { $0.key.id.description < $1.key.id.description })
            .map { LockEntity(information: $0.value) }
        return .result(value: locks)
    }
}
