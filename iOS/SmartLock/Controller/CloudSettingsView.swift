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
    
    @State
    var isCloudUpdating = false
    
    // MARK: - View
    
    var body: some View {
        List {
            Section(header: Text(verbatim: ""), footer: Text(verbatim: "Automatically backup data such as your keys, events and application data.")) {
                Toggle(isOn: $preferences.isCloudBackupEnabled) {
                    Text("iCloud Backup")
                }
            }
            Section(header: Text(verbatim: ""),
                    footer: preferences.lastCloudUpdate
                        .flatMap { Text("Last successful backup: \($0)") } ?? Text("")) {
                if preferences.isCloudBackupEnabled {
                    Button(action: { self.backup() }) {
                        isCloudUpdating ? Text("Backing Up...") : Text("Back Up Now")
                    }
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
        guard isCloudUpdating == false else { return }
        isCloudUpdating = true
        let viewController = AppDelegate.shared.tabBarController
        AppDelegate.shared.tabBarController.syncCloud {
            self.isCloudUpdating = false
            switch $0 {
            case let .failure(error):
                log("⚠️ Could not sync iCloud: \(error.localizedDescription)")
                viewController.showErrorAlert(error.localizedDescription)
            case .success:
                break
            }
        }
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
