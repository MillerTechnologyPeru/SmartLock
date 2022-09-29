//
//  ContentView.swift
//  LockWatch Watch App
//
//  Created by Alsey Coleman Miller on 9/28/22.
//

import SwiftUI
import LockKit

struct ContentView: View {
    
    @EnvironmentObject
    var store: Store
    
    var body: some View {
        NavigationView {
            KeysView()
        }
        .onAppear {
            reload()
        }
    }
}

private extension ContentView {
    
    func reload() {
        Task {
            do { try await store.forceDownloadCloudApplicationData() } // always override on macOS
            catch { log("⚠️ Unable to automatically sync with iCloud. \(error.localizedDescription)") }
        }
        Task {
            try await store.central.wait(for: .poweredOn)
            try await store.scan(duration: store.preferences.scanDuration)
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
