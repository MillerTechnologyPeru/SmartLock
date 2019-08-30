//
//  BluetoothSettingsView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/30/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import SwiftUI
import LockKit

/// Bluetooth Settings View
@available(iOS 13, *)
struct BluetoothSettingsView: View {
    
    // MARK: - Properties
    
    @ObservedObject
    var preferences: Preferences = Store.shared.preferences
    
    // MARK: - View
    
    var body: some View {
        List {
            Section(header: Text(verbatim: "")) {
                SliderCell(
                    title: Text(verbatim: "Scan Duration"),
                    value: $preferences.scanDuration,
                    from: 1.0,
                    through: 10.0,
                    by: 0.1,
                    text: { Text(verbatim: "\(String(format: "%.1f", $0))s") }
                )
                SliderCell(
                    title: Text("Timeout"),
                    value: $preferences.bluetoothTimeout,
                    from: 1.0,
                    through: 30.0,
                    by: 0.1,
                    text: { Text(verbatim: "\(String(format: "%.1f", $0))s") }
                )
                /*
                SliderCell(
                    title: Text("Write without Response Timeout"),
                    value: $preferences.writeWithoutResponseTimeout,
                    from: 1.0,
                    through: 30.0,
                    by: 0.1,
                    text: { Text(verbatim: "\(String(format: "%.1f", $0))s") }
                )*/
            }
            Section(header: Text(verbatim: "")) {
                Toggle("Filter Duplicates", isOn: $preferences.filterDuplicates)
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text("Bluetooth"), displayMode: .large)
    }
}

#if DEBUG
@available(iOS 13, *)
extension BluetoothSettingsView: PreviewProvider {
    
    static var previews: some View {
        BluetoothSettingsView()
    }
}
#endif
