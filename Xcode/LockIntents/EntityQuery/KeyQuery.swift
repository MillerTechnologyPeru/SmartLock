//
//  KeyQuery.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/23/22.
//

import AppIntents
import LockKit

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
struct KeyQuery: EntityQuery {
    
    @MainActor
    func entities(for identifiers: [UUID]) throws -> [KeyEntity] {
        return Store.shared.applicationData.locks
            .filter { identifiers.contains($0.value.key.id) }
            .map {
                KeyEntity(
                    id: $0.value.key.id,
                    lock: $0.key,
                    name: $0.value.key.name,
                    created: $0.value.key.created,
                    permission: .init(rawValue: $0.value.key.permission.type.rawValue)!,
                    isPending: false,
                    expiration: nil
                )
            }
    }
    
    @MainActor
    func suggestedEntities() throws -> [KeyEntity] {
        return Store.shared.applicationData.locks
            .map {
                KeyEntity(
                    id: $0.value.key.id,
                    lock: $0.key,
                    name: $0.value.key.name,
                    created: $0.value.key.created,
                    permission: .init(rawValue: $0.value.key.permission.type.rawValue)!,
                    isPending: false,
                    expiration: nil
                )
            }
    }
}
