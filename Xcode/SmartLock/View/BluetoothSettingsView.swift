//
//  BluetoothSettingsView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/30/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

#if os(iOS) || os(macOS)
import Foundation
import SwiftUI
import LockKit

/// Bluetooth Settings View
struct BluetoothSettingsView: View {
    
    // MARK: - Properties
    
    @ObservedObject
    var preferences: Preferences = Store.shared.preferences
    
    // MARK: - View
    
    var body: some View {
        List {
            Section(header: Text(verbatim: "")) {
                SliderCell(
                    title: Text("Scan Duration"), //R.string.bluetoothSettingsView.bluetoothScanDuration()),
                    value: $preferences.scanDuration,
                    from: 1.0,
                    through: 10.0,
                    by: 0.1,
                    text: { Text(verbatim: "\(String(format: "%.1f", $0))s") }
                )
                SliderCell(
                    title: Text("Timeout"), //R.string.bluetoothSettingsView.bluetoothTimeout()),
                    value: $preferences.bluetoothTimeout,
                    from: 1.0,
                    through: 30.0,
                    by: 0.1,
                    text: { Text(verbatim: "\(String(format: "%.1f", $0))s") }
                )
                /*
                SliderCell(
                    title: Text(R.string.bluetoothSettingsView.bluetoothWrite()),
                    value: $preferences.writeWithoutResponseTimeout,
                    from: 1.0,
                    through: 30.0,
                    by: 0.1,
                    text: { Text(verbatim: "\(String(format: "%.1f", $0))s") }
                )*/
            }
            Section(header: Text(verbatim: "")) {
                Toggle("Filter Duplicates"/*R.string.bluetoothSettingsView.bluetoothFilterDuplicates()*/, isOn: $preferences.filterDuplicates)
                #if !targetEnvironment(macCatalyst)
                Toggle("Monitor Notifications"/*R.string.bluetoothSettingsView.bluetoothMonitorNotifications()*/, isOn: $preferences.monitorBluetoothNotifications)
                #endif
            }
        }
        #if os(iOS)
        .listStyle(GroupedListStyle())
        #endif
        .navigationTitle("Bluetooth")
    }
}

#if DEBUG
extension BluetoothSettingsView: PreviewProvider {
    
    static var previews: some View {
        BluetoothSettingsView()
    }
}
#endif
#endif
