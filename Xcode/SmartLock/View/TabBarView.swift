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
                Label("Nearby", systemImage: "location.circle.fill")
            }
            
            // Keys
            NavigationView {
                EmptyView()
                Text("Select a lock")
            }
            .tabItem {
                Label("Keys", systemImage: "key.fill")
            }
            
            // Keys
            NavigationView {
                EmptyView()
            }
            .tabItem {
                Label("History", systemImage: "clock.fill")
            }
            
            // Settings
            NavigationView {
                SettingsView()
                Text("Settings detail")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .navigationViewStyle(.stack)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
#endif
