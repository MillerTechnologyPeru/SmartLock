//
//  TabBarView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

#if os(iOS)
import SwiftUI
import LockKit

struct TabBarView: View {
    var body: some View {
        TabView {
            // Nearby
            NavigationView {
                NearbyDevicesView()
                Text("Select a lock")
            }
            .tabItem {
                Label("Nearby", systemSymbol: .locationCircleFill)
            }
            
            // Keys
            NavigationView {
                KeysView()
                Text("Select a lock")
            }
            .tabItem {
                Label("Keys", systemSymbol: .keyFill)
            }
            
            // History
            NavigationView {
                EventsView()
            }
            .tabItem {
                Label("History", systemSymbol: .clockFill)
            }
            
            // Settings
            NavigationView {
                SettingsView()
                Text("Settings detail")
            }
            .tabItem {
                Label("Settings", systemSymbol: .gearshapeFill)
            }
        }
        .navigationViewStyle(.stack)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                do { try await Store.shared.syncCloud() }
                catch { log("⚠️ Unable to automatically sync with iCloud. \(error)") }
            }
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
#endif
