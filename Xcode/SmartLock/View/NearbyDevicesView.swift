//
//  NearbyDevicesView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import SwiftUI
import LockKit

struct NearbyDevicesView: View {
    
    @ObservedObject
    var store: Store = .shared
    
    var body: some View {
        #if os(iOS)
        list
            .navigationBarTitle(Text("Nearby"), displayMode: .automatic)
            .navigationBarItems(trailing: trailingButtonItem)
            .tabItem {
                Label("Nearby", image: "NearTabBarIconSelected")
            }
        #elseif os(macOS)
        list
            .navigationTitle(Text("Nearby"))
        #endif
    }
}

private extension NearbyDevicesView {
    
    var peripherals: [NativePeripheral] {
        store.peripherals
            .lazy
            .sorted(by: { $0.value.rssi < $1.value.rssi })
            .map { $0.key }
    }
    
    var list: some View {
        List {
            ForEach(peripherals, id: \.id) {
                LockRowView(image: .permission(.admin), title: "\($0)")
            }
        }
        .refreshable {
            Task {
                await store.scan()
                try await Task.sleep(nanoseconds: 2 * 1_000_000_00)
            }
        }
        .task {
            await store.scan()
        }
        .onDisappear {
            Task {
                store.stopScanning()
            }
        }
    }
    
    var trailingButtonItem: some View {
        EmptyView()
    }
}

struct NearbyDevicesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TabView {
                NearbyDevicesView()
            }
        }
    }
}
