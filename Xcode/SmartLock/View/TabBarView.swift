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
    
    //@State
    //private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    
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
