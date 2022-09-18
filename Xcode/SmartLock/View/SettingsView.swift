//
//  SettingsView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .navigationBarTitle(Text("Settings"), displayMode: .automatic)
            .tabItem {
                Label("Settings", image: "SettingsTabBarIconSelected")
            }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TabView {
                SettingsView()
            }
        }
    }
}
