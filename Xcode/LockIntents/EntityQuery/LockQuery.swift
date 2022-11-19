//
//  LockQuery.swift
//  LockIntents
//
//  Created by Alsey Coleman Miller on 9/22/22.
//

import AppIntents
import LockKit

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
struct LockQuery: EntityQuery {
    
    @MainActor
    func entities(for identifiers: [UUID]) throws -> [LockEntity] {
        return cachedLocks.filter { identifiers.contains($0.id) }
    }
    
    @MainActor
    func suggestedEntities() throws -> [LockEntity] {
        return cachedLocks
    }
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
private extension LockQuery {
    
    @MainActor
    var cachedLocks: [LockEntity] {
        return Store.shared.applicationData.locks.lazy
            .sorted { $0.value.key.created < $1.value.key.created }
            .map {
            LockEntity(
                id: $0.key,
                buildVersion: $0.value.information.buildVersion.rawValue,
                version: $0.value.information.version.rawValue,
                status: .init(rawValue: $0.value.information.status.rawValue)!,
                unlockActions: .init($0.value.information.unlockActions.map { .init(rawValue: $0.rawValue)! }),
                name: $0.value.name,
                key: .init(key: $0.value.key, lock: $0.key)
            )
        }
    }
}
