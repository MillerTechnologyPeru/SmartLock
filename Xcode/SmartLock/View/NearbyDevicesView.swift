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
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(peripherals, id: \.id) {
                    Text(verbatim: $0.id.description)
                }
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
        NearbyDevicesView()
    }
}
