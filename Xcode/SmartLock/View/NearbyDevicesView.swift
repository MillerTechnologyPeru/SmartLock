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
}

extension NearbyDevicesView {
    
    var peripherals: [NativePeripheral] {
        store.peripherals
            .lazy
            .sorted(by: { $0.value.rssi < $1.value.rssi })
            .map { $0.key }
    }
}

struct NearbyDevicesView_Previews: PreviewProvider {
    static var previews: some View {
        NearbyDevicesView()
    }
}
