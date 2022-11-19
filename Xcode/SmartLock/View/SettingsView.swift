//
//  SettingsView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

#if os(iOS)
import SwiftUI
import LockKit

struct SettingsView: View {
    
    var body: some View {
        List {
            Section {
                SettingsRowView(
                    title: "Logs",
                    icon: .logs,
                    destination: Text("Logs")
                )
            }
            Section(content: {
                SettingsRowView(
                    title: "Bluetooth",
                    icon: .bluetooth,
                    destination: BluetoothSettingsView()
                )
                SettingsRowView(
                    title: "iCloud",
                    icon: .cloud,
                    destination: CloudSettingsView()
                )
            }, footer: {
                Text(verbatim: version)
                    .font(.footnote)
                    .foregroundColor(.gray)
            })
        }
        .listStyle(.grouped)
        .navigationTitle("Settings")
    }
}

private extension SettingsView {
    
    var version: String {
        "v\(Bundle.InfoPlist.shortVersion) (\(Bundle.InfoPlist.version))"
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
#endif
