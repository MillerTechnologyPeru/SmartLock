//
//  Shortcuts.swift
//  LockIntents
//
//  Created by Alsey Coleman Miller on 9/22/22.
//

import AppIntents

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
struct AppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScanLocksIntent(),
            phrases: [
                "Scan for locks with \(.applicationName)",
            ],
            systemImageName: "lock"
        )
    }
}
