//
//  SmartLockApp.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import SwiftUI
import LockKit

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

@main
struct LockApp: App {
    
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    #elseif os(iOS) || os(tvOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    #endif
    
    var body: some Scene {
        // main window
        WindowGroup {
            ContentView()
                .environmentObject(Store.shared)
                .environment(\.managedObjectContext, Store.shared.managedObjectContext)
        }
        
        #if os(macOS)
        Window("Nearby", id: "nearby") {
            NavigationStack {
                NearbyDevicesView()
                    .navigationDestination(for: AppNavigationLinkID.self) {
                        AppNavigationDestinationView(id: $0)
                    }
            }
            .environmentObject(Store.shared)
            .environment(\.managedObjectContext, Store.shared.managedObjectContext)
        }
        
        Window("Keys", id: "keys") {
            NavigationStack {
                KeysView()
                    .navigationDestination(for: AppNavigationLinkID.self) {
                        AppNavigationDestinationView(id: $0)
                    }
            }
            .environmentObject(Store.shared)
            .environment(\.managedObjectContext, Store.shared.managedObjectContext)
        }
        
        Settings {
            NavigationStack {
                SettingsView()
            }
            .environmentObject(Store.shared)
            .environment(\.managedObjectContext, Store.shared.managedObjectContext)
        }
        #endif
    }
    
    init() {
        // print app info
        log("Launching SmartLock v\(Bundle.InfoPlist.shortVersion) (\(Bundle.InfoPlist.version))")
    }
}

#if os(iOS)
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - UIApplicationDelegate
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // set app appearance
        //UIView.configureLockAppearance()
        
        return true
    }
    
    func applicationDidBecomeActive(
        _ application: UIApplication
    ) {
        
        Task {
            do { try await Store.shared.syncCloud() }
            catch { log("⚠️ Unable to automatically sync with iCloud. \(error)") }
        }
    }
}
#elseif os(macOS)
final class AppDelegate: NSResponder, NSApplicationDelegate {
    
    // MARK: - NSApplicationDelegate
    
    
    
    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        return false
    }
}
#endif
