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
    
    #endif
    
    var body: some Scene {
        // main window
        WindowGroup {
            ContentView()
                .environmentObject(Store.shared)
                .environment(\.managedObjectContext, Store.shared.managedObjectContext)
                .onAppear {
                    _ = LockApp.initialize
                }
                .onContinueUserActivity("") { _ in
                    
                }
        }
        
        #if os(macOS)
        
        WindowGroup("Nearby") {
            NavigationStack {
                NearbyDevicesView()
            }
        }
        
        Settings {
            NavigationStack {
                SettingsView()
            }
        }
        #endif
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

#if os(macOS)
final class AppDelegate: NSResponder, NSApplicationDelegate {
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
#endif
