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
import Network

/// iCloud Settings View
@available(iOS 13, *)
struct CloudSettingsView: View {
    
    // MARK: - Properties
    
    @ObservedObject
    var preferences: Preferences = Store.shared.preferences
    
    @ObservedObject
    var networkMonitor: NetworkMonitor = .shared
    
    @State
    var isCloudUpdating = false
    
    // MARK: - View
    
    var body: some View {
        List {
            Section(header: Text(verbatim: ""), footer: Text(R.string.cloudSettingsView.cloudFooter())) {
                Toggle(isOn: $preferences.isCloudBackupEnabled) {
                    Text(R.string.cloudSettingsView.cloudToggle())
                }
            }
            Section(header: Text(verbatim: ""),
                    footer: preferences.isCloudBackupEnabled ? preferences.lastCloudUpdate
                        .flatMap { Text(R.string.cloudSettingsView.cloudLastUpdate()) + Text(" \($0)") } ?? Text("") : Text("")) {
                if preferences.isCloudBackupEnabled && networkMonitor.path.status != .unsatisfied {
                    Button(action: { self.backup() }) {
                        HStack {
                            isCloudUpdating ? Text(R.string.cloudSettingsView.cloudBackup()) : Text(R.string.cloudSettingsView.cloudBackupNow())
                            Spacer()
                            if isCloudUpdating {
                                ActivityIndicator()
                            }
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text(R.string.cloudSettingsView.cloudICloud()), displayMode: .large)
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
