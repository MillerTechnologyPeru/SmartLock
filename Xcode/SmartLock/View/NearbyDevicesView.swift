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
        StateView(
            state: state,
            items: items,
            reload: reload,
            destination: {
                Text(verbatim: "\($0)")
            }
        )
    }
}

private extension NearbyDevicesView {
    
    func reload() async {
        guard await store.central.state == .poweredOn else {
            return
        }
        await store.scan()
        Task {
            let loading = {
                store.peripherals
                    .keys
                    .filter { !store.lockInformation.keys.contains($0) }
            }
            try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            while store.isScanning, loading().isEmpty {
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            }
            // stop scanning and load info for unknown devices
            store.stopScanning()
            for peripheral in loading() {
                do {
                    let information = try await store.readInformation(for: peripheral)
                    log("Read information for lock \(information.id)")
                    #if DEBUG
                    dump(information)
                    #endif
                } catch {
                    log("⚠️ Unable to load information for peripheral \(peripheral). \(error)")
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
                if let key = store.lockInformation[peripheral] { //store[lock: information.id] {
                    return .key(peripheral.id, "", .admin)
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
        
        let reload: () async -> ()
        
        let destination: (Item) -> (Destination)
        
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
}

private extension NearbyDevicesView.StateView {
    
    var list: some View {
        List {
            ForEach(items) { (item) in
                NavigationLink(destination: {
                    destination(item)
                }, label: {
                    LockRowView(item)
                })
            }
        }
        .refreshable {
            guard state == .stopScan else {
                return
            }
            Task {
                await reload()
            }
        }
        .task {
            await reload()
        }
        .listStyle(.plain)
    }
    
    var trailingButtonItem: some View {
        switch state {
        case .bluetoothUnavailable:
            return AnyView(
                Text(verbatim: "⚠️")
            )
        case .scanning:
            return AnyView(
                Button(action: {
                    
                }, label: {
                    Image(systemName: "stop.fill")
                })
            )
        case .stopScan:
            return AnyView(
                Button(action: {
                    
                }, label: {
                    Image(systemName: "arrow.clockwise")
                })
            )
        }
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
        case let .setup(_, id):
            self.init(
                image: .permission(.owner),
                title: "Setup",
                subtitle: id.description
            )
        case let .unknown(_, id):
            self.init(
                image: .permission(.anytime),
                title: "Lock",
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
                reload: {  },
                destination: { Text(verbatim: $0.id.uuidString) }
            )
        }
    }
}
