//
//  CloudSettingsView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/30/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

#if os(iOS) || os(macOS)
import Foundation
import SwiftUI
import LockKit
import Network
import CloudKit

/// iCloud Settings View
struct CloudSettingsView: View {
    
    // MARK: - Properties
    
    @ObservedObject
    var preferences: Preferences = Store.shared.preferences
    
    @ObservedObject
    var networkMonitor: NetworkMonitor = .shared
    
    @ObservedObject
    var cloudCache: CloudCache = .shared
    
    // MARK: - View
    
    var body: some View {
        List {
            Section(header: Text(verbatim: ""), footer: Text(""/*R.string.cloudSettingsView.cloudFooter()*/)) {
                Toggle(isOn: $preferences.isCloudBackupEnabled) {
                    Text("Enable Cloud Backup")//R.string.cloudSettingsView.cloudToggle())
                }
            }/*
            Section(header: Text(verbatim: ""),
                    footer: preferences.isCloudBackupEnabled ? preferences.lastCloudUpdate
                        .flatMap { Text("Last Update"/*R.string.cloudSettingsView.cloudLastUpdate()*/) + Text(" \($0)") } ?? Text("") : Text("")) {
                if preferences.isCloudBackupEnabled
                    && networkMonitor.path.status != .unsatisfied
                    && cloudCache.status == .available {
                    Button(action: { self.cloudCache.backup() }) {
                        HStack {
                            cloudCache.isCloudUpdating ? Text("Is uploading Backup"/*R.string.cloudSettingsView.cloudBackup()*/) : Text("Backup Now")//R.string.cloudSettingsView.cloudBackupNow())
                            Spacer()
                            if cloudCache.isCloudUpdating {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                    }
                }
            }*/
        }
        .listStyle(.grouped)
        .navigationTitle("iCloud"/*Text(R.string.cloudSettingsView.cloudICloud()*/)
        .onAppear { self.cloudCache.refreshStatus() }
    }
}

// MARK: - Supporting Types

@available(iOS 13, *)
internal extension CloudSettingsView {
    
    final class CloudCache: ObservableObject {
        
        static let shared = CloudCache()
        
        let cloudStore: CloudStore = .shared
        
        @Published
        var status: CKAccountStatus = .couldNotDetermine
        
        @Published
        var isCloudUpdating = false
        
        func refreshStatus() {
            Task {
                do {
                    let status = try await cloudStore.accountStatus()
                    await MainActor.run {
                        self.status = status
                    }
                } catch {
                    log("⚠️ Could load iCloud account: \(error.localizedDescription)")
                }
            }
        }
        
        func backup() {
            
            guard isCloudUpdating == false else { return }
            isCloudUpdating = true
            /*
            let viewController = AppDelegate.shared.tabBarController
            viewController.syncCloud { (result) in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isCloudUpdating = false
                    switch result {
                    case let .failure(error):
                        log("⚠️ Could not sync iCloud: \(error.localizedDescription)")
                        viewController.showErrorAlert(error.localizedDescription)
                    case .success:
                        break
                    }
                }
            }*/
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 13.0.0, *)
extension CloudSettingsView: PreviewProvider {
    static var previews: some View {
        CloudSettingsView()
    }
}
#endif
#endif
