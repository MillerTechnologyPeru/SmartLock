//
//  CloudSettingsView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/30/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import SwiftUI
import LockKit

/// iCloud Settings View
@available(iOS 13, *)
struct CloudSettingsView: View {
    
    // MARK: - Properties
    
    @ObservedObject
    var preferences: Preferences = Store.shared.preferences
    
    // MARK: - View
    
    var body: some View {
        List {
            Section(header: Text(verbatim: "")) {
                Toggle(isOn: $preferences.isCloudEnabled) {
                    Text("iCloud Syncronization")
                }
            }
            Section(header: Text(verbatim: "")) {
                if preferences.isCloudEnabled {
                    Button(action: { self.backup() }) {
                        Text("Backup now")
                    }
                    preferences.lastCloudUpdate.flatMap {
                        Text("Last updated \($0)")
                    } ?? Text("Never updated")
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text("iCloud"), displayMode: .large)
    }
}

// MARK: - Methods

@available(iOS 13, *)
private extension CloudSettingsView {
    
    func backup() {
        AppDelegate.shared.tabBarController.syncCloud()
    }
}

#if DEBUG
@available(iOS 13.0.0, *)
extension CloudSettingsView: PreviewProvider {
    static var previews: some View {
        CloudSettingsView()
    }
}
#endif
