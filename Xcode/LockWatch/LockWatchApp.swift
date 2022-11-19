//
//  LockWatchApp.swift
//  LockWatch Watch App
//
//  Created by Alsey Coleman Miller on 9/28/22.
//

import SwiftUI
import LockKit

@main
struct LockWatchApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(Store.shared)
                .environment(\.managedObjectContext, Store.shared.managedObjectContext)
        }
    }
}
