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
        TVContentView()
        #endif
    }
}

// MARK: - Preview

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
