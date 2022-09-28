//
//  ContentView.swift
//  LockWatch Watch App
//
//  Created by Alsey Coleman Miller on 9/28/22.
//

import SwiftUI
import LockKit

struct ContentView: View {
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
            do { try await Store.shared.syncCloud(conflicts: { _ in return true }) } // always override on watchOS
            catch { log("⚠️ Unable to automatically sync with iCloud. \(error)") }
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
