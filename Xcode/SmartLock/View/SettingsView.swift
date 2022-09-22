//
//  SettingsView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import SwiftUI

struct SettingsView: View {
    
    var body: some View {
        List {
            Text("Setting 1")
            Text("Setting 2")
        }
            .navigationTitle("Settings")
    }
}

#if DEBUG
@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
#endif
