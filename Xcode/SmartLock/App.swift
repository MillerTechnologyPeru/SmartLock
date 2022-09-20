//
//  SmartLockApp.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import SwiftUI
import LockKit

@main
struct LockApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(Store.shared)
                .environment(\.managedObjectContext, Store.shared.managedObjectContext)
                .onAppear {
                    _ = LockApp.initialize
                    Task {
                        do { try await Store.shared.syncCloud() }
                        catch { log("⚠️ Unable to automatically sync with iCloud") }
                    }
                }
                .onContinueUserActivity("") { _ in
                    
                }
        }
    }
    
    init() {
        // print app info
        log("Launching SmartLock v\(Bundle.InfoPlist.shortVersion) (\(Bundle.InfoPlist.version))")
    }
    
    static let initialize: () = {
        #if canImport(UIKit)
        // set app appearance
        //UIView.configureLockAppearance()
        #endif
    }()
}
