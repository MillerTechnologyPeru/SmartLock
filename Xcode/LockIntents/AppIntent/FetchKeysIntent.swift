//
//  FetchKeysIntent.swift
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
struct FetchKeysIntent: AppIntent {
    
    static var title: LocalizedStringResource { "Fetch Keys" }
    
    static var description: IntentDescription {
        IntentDescription(
            "Fetch the keys for a specified lock.",
            categoryName: "Utility",
            searchKeywords: ["key", "bluetooth", "lock"]
        )
    }
    
    /// The specified lock to unlock.
    @Parameter(
        title: "Lock",
        description: "The specified lock to fetch keys from."
    )
    var lock: LockEntity
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let store = Store.shared
        // search for lock if not in cache
        guard let peripheral = try await store.device(for: lock.id) else {
            throw LockError.notInRange(lock: lock.id)
        }
        // fetch events
        let keysList = try await store.listKeys(for: peripheral)
        let keys = keysList.keys.map { KeyEntity(key: $0, lock: lock.id) }
            + keysList.newKeys.map { KeyEntity(newKey: $0, lock: lock.id) }
        return .result(
            value: keys,
            view: view(for: keysList)
        )
    }
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
@MainActor
private extension FetchKeysIntent {
    
    static let relativeDateTimeFormatter: RelativeDateTimeFormatter = {
        let dateFormatter = RelativeDateTimeFormatter()
        dateFormatter.dateTimeStyle = .numeric
        dateFormatter.unitsStyle = .spellOut
        return dateFormatter
    }()
    
    func view(for list: KeysList) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                if list.isEmpty {
                    Text("No keys found.")
                        .padding(20)
                } else {
                    if list.count > 4 {
                        Text("Found \(list.count) keys.")
                            .padding(20)
                    } else {
                        ForEach(list.keys) {
                            view(for: $0)
                        }
                        if list.newKeys.isEmpty == false {
                            Section("Pending") {
                                ForEach(list.newKeys) {
                                    view(for: $0)
                                }
                            }
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
    
    func view(for key: Key) -> some View {
        #if os(watchOS)
        LockRowView(
            image: .image(Image(permissionType: key.permission.type)),
            title: key.name,
            subtitle: key.permission.localizedText
        )
        #else
        LockRowView(
            image: .image(Image(permissionType: key.permission.type)),
            title: key.name,
            subtitle: key.permission.localizedText,
            trailing: (
                key.created.formatted(date: .numeric, time: .omitted),
                key.created.formatted(date: .omitted, time: .shortened)
            )
        )
        #endif
    }
    
    func view(for key: NewKey) -> some View {
        #if os(watchOS)
        LockRowView(
            image: .image(Image(permissionType: key.permission.type)),
            title: key.name,
            subtitle: key.permission.localizedText + "\n" + "Expires " + FetchKeysIntent.relativeDateTimeFormatter.localizedString(for: key.expiration, relativeTo: Date())
        )
        #else
        LockRowView(
            image: .image(Image(permissionType: key.permission.type)),
            title: key.name,
            subtitle: key.permission.localizedText + "\n" + "Expires " + FetchKeysIntent.relativeDateTimeFormatter.localizedString(for: key.expiration, relativeTo: Date()),
            trailing: (
                key.created.formatted(date: .numeric, time: .omitted),
                key.created.formatted(date: .omitted, time: .shortened)
            )
        )
        #endif
    }
}
