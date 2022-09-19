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
            NavigationView {
                NearbyDevicesView()
                Text("Select a lock")
            }
            .tabItem {
                Label("Nearby", image: "NearTabBarIconSelected")
            }
            NavigationView {
                SettingsView()
                Text("Settings detail")
            }
            .tabItem {
                Label("Settings", image: "SettingsTabBarIconSelected")
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
