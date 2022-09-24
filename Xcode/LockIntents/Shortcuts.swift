//
//  Shortcuts.swift
//  LockIntents
//
//  Created by Alsey Coleman Miller on 9/22/22.
//

import AppIntents

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
struct AppShortcuts: AppShortcutsProvider {
    
    /// The background color of the tile that Shortcuts displays for each of the app's App Shortcuts.
    static var shortcutTileColor: ShortcutTileColor {
        .navy
    }

    static var appShortcuts: [AppShortcut] {
        
        // Scan
        AppShortcut(
            intent: ScanLocksIntent(),
            phrases: [
                "Scan for locks with \(.applicationName)",
            ],
            systemImageName: "arrow.clockwise"
        )
        
        // Unlock
        AppShortcut(
            intent: UnlockIntent(),
            phrases: [
                "Unlock my door with \(.applicationName)",
            ],
            systemImageName: "lock.open.fill"
        )
    }
}
