//
//  Shortcuts.swift
//  LockIntents
//
//  Created by Alsey Coleman Miller on 9/22/22.
//

import AppIntents

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
