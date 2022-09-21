//
//  NearbyDevicesView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import SwiftUI
import LockKit

struct NearbyDevicesView: View {
    
    @EnvironmentObject
    var store: Store
    
    @SwiftUI.State
    private var scanTask: TaskQueue.PendingTask?
    
    var body: some View {
        StateView<AnyView>(
            state: state,
            items: items,
            toggleScan: toggleScan,
            destination: { (item) in
                if let information = store.lockInformation.first(where: { $0.key.id == item.id })?.value {
                    return AnyView(LockDetailView(id: information.id))
                } else {
                    return AnyView(EmptyView())
                }
            }
        )
        .onAppear {
            Task {
                // start scanning after delay
                try? await Task.sleep(timeInterval: 0.7)
                if store.isScanning == false {
                    toggleScan()
                }
            }
        }
        .onDisappear {
            if store.isScanning {
                store.stopScanning()
            }
        }
    }
}

private extension NearbyDevicesView {
    
    func toggleScan() {
        if store.isScanning {
            store.stopScanning()
        } else {
            Task {
                await scanTask?.cancel()
                await TaskQueue.bluetooth.cancelAll() // stop all pending operations to scan
                scanTask = await Task.bluetooth {
                    guard await store.central.state == .poweredOn,
                          store.isScanning == false else {
                        return
                    }
                    await store.scan()
                }
            }
        }
    }
    
    var peripherals: [NativePeripheral] {
        store.peripherals
            .lazy
            .sorted(by: { $0.value.rssi < $1.value.rssi })
            .map { $0.key }
    }
    
    var state: State {
        if store.state != .poweredOn {
            return .bluetoothUnavailable
        } else if store.isScanning {
            return .scanning
        } else {
            return .stopScan
        }
    }
    
    var items: [Item] {
        peripherals.map { item(for: $0) }
    }
    
    func item(for peripheral: NativePeripheral) -> Item {
        if let information = store.lockInformation[peripheral] {
            switch information.status {
            case .setup:
                return .setup(peripheral.id, information.id)
            default:
                if let lockCache = store[lock: information.id] {
                    return .key(peripheral.id, lockCache.name, lockCache.key.permission.type)
                } else {
                    return .unknown(peripheral.id, information.id)
                }
            }
        } else {
            return .loading(peripheral.id)
        }
    }
}

extension NearbyDevicesView {
    
    struct StateView <Destination>: View where Destination: View {
        
        let state: State
        
        let items: [Item]
        
        let toggleScan: () -> ()
        
        let destination: (Item) -> (Destination)
        
        var body: some View {
            #if os(iOS)
            list
                .navigationTitle(title)
                .navigationBarItems(trailing: trailingButtonItem)
            #elseif os(macOS)
            list
                .navigationTitle(title)
            #endif
        }
    }
}

private extension NearbyDevicesView.StateView {
    
    var title: LocalizedStringKey {
        "Nearby"
    }
    
    var list: some View {
        List {
            ForEach(items) { (item) in
                switch item {
                case .loading, .unknown:
                    LockRowView(item)
                case .key, .setup:
                    NavigationLink(destination: {
                        destination(item)
                    }, label: {
                        LockRowView(item)
                    })
                }
            }
        }
    }
    
    var trailingButtonItem: some View {
        Button(action: {
            toggleScan()
        }, label: {
            switch state {
            case .bluetoothUnavailable:
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.monochrome)
            case .scanning:
                Image(systemName: "stop.fill")
                    .symbolRenderingMode(.monochrome)
            case .stopScan:
                Image(systemName: "arrow.clockwise")
                    .symbolRenderingMode(.monochrome)
            }
        })
    }
}

// MARK: - Supporting Types

extension NearbyDevicesView {
    
    enum State {
        case bluetoothUnavailable
        case scanning
        case stopScan
    }
}

extension NearbyDevicesView {
    
    enum Item {
        case loading(NativeCentral.Peripheral.ID)
        case setup(NativeCentral.Peripheral.ID, UUID)
        case key(NativeCentral.Peripheral.ID, String, PermissionType)
        case unknown(NativeCentral.Peripheral.ID, UUID)
    }
}

extension NearbyDevicesView.Item: Identifiable {
    
    var id: NativeCentral.Peripheral.ID {
        switch self {
        case let .loading(id):
            return id
        case let .setup(id, _):
            return id
        case let .key(id, _, _):
            return id
        case let .unknown(id, _):
            return id
        }
    }
}

extension LockRowView {
    
    init(_ item: NearbyDevicesView.Item) {
        switch item {
        case .loading:
            self.init(
                image: .loading,
                title: "Loading..."
            )
        case let .unknown(_, id):
            self.init(
                image: .permission(.anytime),
                title: "Lock",
                subtitle: id.description
            )
        case let .setup(_, id):
            self.init(
                image: .permission(.owner),
                title: "Setup",
                subtitle: id.description
            )
        case let .key(_, name, type):
            self.init(
                image: .permission(type),
                title: name,
                subtitle: type.localizedText
            )
        }
    }
}

// MARK: - Preview

struct NearbyDevicesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NearbyDevicesView.StateView(
                state: .scanning,
                items: [
                    .loading(UUID()),
                    .setup(UUID(), UUID()),
                    .unknown(UUID(), UUID()),
                    .key(UUID(), "My lock", .admin)
                ],
                toggleScan: {  },
                destination: { Text(verbatim: $0.id.uuidString) }
            )
        }
    }
}
