//
//  LockQuery.swift
//  LockIntents
//
//  Created by Alsey Coleman Miller on 9/22/22.
//

import AppIntents
import LockKit

struct LockQuery: EntityQuery {
    
    func entities(for identifiers: [UUID]) async throws -> [LockEntity] {
        let store = await Store.shared
        return await store.applicationData.locks
            .filter { identifiers.contains($0.key) }
            .map {
            LockEntity(
                id: $0.key,
                buildVersion: $0.value.information.buildVersion.rawValue,
                version: $0.value.information.version.rawValue,
                status: $0.value.information.status,
                unlockActions: $0.value.information.unlockActions
            )
        }
    }
}
