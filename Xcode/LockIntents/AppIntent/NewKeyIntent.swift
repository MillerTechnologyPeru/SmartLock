//
//  NewKeyIntent.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/25/22.
//

import Foundation
import AppIntents
import CoreData
import SwiftUI
import LockKit

/// Intent for fetching events
@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
struct NewKeyIntent: AppIntent {
    
    static var title: LocalizedStringResource { "New Key" }
    
    static var description: IntentDescription {
        IntentDescription(
            "Create a new key for a specified lock.",
            categoryName: "Utility",
            searchKeywords: ["key", "bluetooth", "lock"]
        )
    }
    
    /// The specified lock to create a new key.
    @Parameter(
        title: "Lock",
        description: "The specified lock to create a new key."
    )
    var lock: LockEntity
    
    /// The specified lock to create a new key.
    @Parameter(
        title: "Name",
        description: "The name of the new key."
    )
    var name: String
    
    /// The permission of the new key.
    @Parameter(
        title: "Permission",
        description: "The specified permission of the new key."
    )
    var permission: PermissionAppEnum
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let store = Store.shared
        // search for lock if not in cache
        guard let peripheral = try await store.device(for: lock.id) else {
            throw LockError.notInRange(lock: lock.id)
        }
        let name = name.isEmpty ? "New \(permission) Key" : self.name
        // fetch events
        let invitation = try await store.newKey(
            for: peripheral,
            permission: .anytime, //PermissionType(rawValue: permission.rawValue)!,
            name: name
        )
        let fileName = "newKey-\(invitation.key.id).ekey"
        let encoder = JSONEncoder()
        let data = try encoder.encode(invitation)
        let file = IntentFile(data: data, filename: fileName)
        return .result(
            value: file
        )
    }
}
