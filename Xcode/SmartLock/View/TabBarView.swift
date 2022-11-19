//
//  TabBarView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

#if os(iOS)
import SwiftUI
import LockKit
import SFSafeSymbols

struct TabBarView: View {
    
    @EnvironmentObject
    var store: Store
    
    //@State
    //private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    
    @State
    private var sheet: AppNavigationDestinationView?
    
    @State
    private var error: Error?
    
    var body: some View {
        TabView {
            
            // Nearby
            SplitView(
                title: "Nearby",
                systemSymbol: .locationCircleFill,
                sidebar: { NearbyDevicesView() },
                detail: { Text("Select a lock") }
            )
            
            // Keys
            SplitView(
                title: "Keys",
                systemSymbol: .keyFill,
                sidebar: { KeysView() },
                detail: { Text("Select a lock") }
            )
            
            // History
            NavigationView {
                EventsView()
            }
            .tabItem {
                Label("History", systemSymbol: .clockFill)
            }
            .navigationViewStyle(.stack)
            
            // Settings
            NavigationView {
                SettingsView()
                Text("Settings detail")
            }
            .tabItem {
                Label("Settings", systemSymbol: .gearshapeFill)
            }
            .navigationViewStyle(.stack)
        }
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            store.beaconController.allowsBackgroundLocationUpdates = true
            store.beaconController.requestAlwaysAuthorization()
        }
        .onOpenURL { url in
            open(url: url)
        }
        .sheet(item: $sheet) { view in
            NavigationView {
                view
                    .toolbar {
                        ToolbarItem(placement: .navigation) {
                            Text("Cancel")
                        }
                }
            }
        }
        .alert(error: $error)
    }
}

@MainActor
extension TabBarView {
    
    func open(url: URL) {
        self.error = nil
        log("Open \(url.description)")
        Task {
            do {
                try await open(url: url)
            }
            catch {
                log("⚠️ Unable to open URL. \(error.localizedDescription)")
                // show error
                self.error = error
            }
        }
    }
    
    func open(url: URL) async throws {
        
        if url.isFileURL {
            try await open(file: url)
        } else if let lockURL = LockURL(rawValue: url) {
            try open(url: lockURL)
        } else {
            throw CocoaError(.fileReadInvalidFileName)
        }
    }
    
    func open(file url: URL) async throws {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let decoder = JSONDecoder()
        let invitation = try decoder.decode(NewKey.Invitation.self, from: data)
        open(invitation: invitation)
    }
    
    func open(invitation: NewKey.Invitation) {
        self.sheet = .init(id: .newKeyInvitation(invitation))
    }
    
    func open(lock: UUID) {
        self.sheet = .init(id: .lock(lock))
    }
    
    func open(url: LockURL) throws {
        switch url {
        case let .newKey(invitation):
            open(invitation: invitation)
        case let .unlock(lock: lock):
            open(lock: lock)
        case let .setup(lock: lock, secret: secretData):
            try setup(lock: lock, using: secretData)
        }
    }
    
    func setup(lock: UUID, using secretData: KeyData) throws {
        guard store.applicationData.locks[lock] == nil else {
            throw LockError.existingKey(lock: lock)
        }
        self.sheet = .init(id: .setup(lock, secretData))
    }
}

extension TabBarView {
    
    struct SplitView <Sidebar: View, Detail: View> : View {
        
        let title: LocalizedStringKey
        
        let systemSymbol: SFSymbol
        
        let sidebar: () -> Sidebar
        
        let detail: () -> Detail
        
        @State
        private var columnVisibilityData: Data?
        
        var body: some View {
            navigationView
                .tabItem {
                    Label(title, systemSymbol: systemSymbol)
                }
        }
    }
}

private extension TabBarView.SplitView {
    
    var navigationView: some View {
        if #available(iOS 16.0, *) {
            return NavigationView {
                sidebar()
            }
            .navigationViewStyle(.stack)
        } else {
            return NavigationView {
                sidebar()
            }
            .navigationViewStyle(.stack)
        }
    }
    
    var navigationStack: some View {
        if #available(iOS 16.0, *) {
            return NavigationSplitView(
                columnVisibility: columnVisibility,
                sidebar: {
                    sidebar()
                },
                detail: {
                    detail()
                }
            )
            .navigationSplitViewStyle(.prominentDetail)
        } else {
            return NavigationView {
                sidebar()
                detail()
            }
            .navigationViewStyle(.stack)
        }
    }
    
    @available(iOS 16.0, *)
    var columnVisibility: Binding<NavigationSplitViewVisibility> {
        Binding(get: {
            let decoder = JSONDecoder()
            return columnVisibilityData.flatMap { try? decoder.decode(NavigationSplitViewVisibility.self, from: $0) } ?? .automatic
        }, set: {
            let encoder = JSONEncoder()
            columnVisibilityData = try? encoder.encode($0)
        })
    }
}

#if DEBUG
struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
#endif

#endif
