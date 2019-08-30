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
            if preferences.isCloudEnabled {
                Button(action: {  }) {
                    Text("Backup now")
                }
            }
        }
        
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text("iCloud"), displayMode: .large)
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
