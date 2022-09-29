//
//  ContentView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(iOS)
        TabBarView()
        #elseif os(macOS)
        SidebarView()
        #elseif os(tvOS)
        NavigationView {
            KeysView()
        }
        #endif
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
