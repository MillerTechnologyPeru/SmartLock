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
    
    @State
    private var scanTask: TaskQueue.PendingTask?
    
    @State
    private var peripherals = [NativePeripheral]()
    
    @State
    private var readInformationTasks = [NativePeripheral: Task<Void, Never>]()
    
    @State
    private var readInformationError = [NativePeripheral: Error]()
    
    var body: some View {
        StateView<AnyView>(
            state: state,
            items: scanResults.map { item(for: $0) },
            toggleScan: toggleScan,
            destination: { (item) in
                if let information = store.lockInformation[item.id] {
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
                    store.scanDefault()
                }
            }
        }
    }
    
    var scanResults: AsyncFetchedResults<ScanResultsAsyncDataSource> {
        .init(dataSource: .init(store: store), configuration: (), results: $peripherals, tasks: $readInformationTasks, errors: $readInformationError)
    }
    
    func item(for element: AsyncFetchedResults<ScanResultsAsyncDataSource>.Element) -> NearbyDevicesView.Item {
        switch element {
        case let .loading(peripheral):
            return .loading(peripheral)
        case let .failure(peripheral, error):
            return .error(peripheral, error.localizedDescription)
        case let .success(peripheral, information):
            switch information.status {
            case .setup:
                return .setup(peripheral, information.id)
            default:
                if let lockCache = store[lock: information.id] {
                    return .lock(peripheral, lockCache.name, lockCache.key.permission.type)
                } else {
                    return .unknown(peripheral, information.id)
                }
            }
        }
    }
    
    var state: ScanState {
        if store.state != .poweredOn {
            return .bluetoothUnavailable
        } else if store.isScanning {
            return .scanning
        } else {
            return .stopScan
        }
    }
}

extension NearbyDevicesView {
    
    struct StateView <Destination>: View where Destination: View {
        
        let state: ScanState
        
        let items: [Item]
        
        let toggleScan: () -> ()
        
        let destination: (Item) -> (Destination)
        
        var body: some View {
            #if os(iOS)
            list
                .navigationTitle(title)
                .navigationBarItems(trailing: scanButton)
            #elseif os(macOS)
            list
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(id: "scan", placement: .primaryAction) { scanButton }
                }
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
                case .loading, .error, .unknown:
                    LockRowView(item)
                case .lock, .setup:
                    NavigationLink(destination: {
                        destination(item)
                    }, label: {
                        LockRowView(item)
                    })
                }
            }
        }
    }
    
    var scanButton: some View {
        Button(action: {
            toggleScan()
        }, label: {
            switch state {
            case .bluetoothUnavailable:
                Image(systemSymbol: .exclamationmarkTriangleFill) //"exclamationmark.triangle.fill"
                    .symbolRenderingMode(.multicolor)
            case .scanning:
                Image(systemSymbol: .stopFill) // "stop.fill"
                    .symbolRenderingMode(.monochrome)
            case .stopScan:
                Image(systemSymbol: .arrowClockwise) // "arrow.clockwise"
                    .symbolRenderingMode(.monochrome)
            }
        })
    }
}

// MARK: - Supporting Types

extension NearbyDevicesView {
    
    enum ScanState {
        case bluetoothUnavailable
        case scanning
        case stopScan
    }
}

extension NearbyDevicesView {
    
    enum Item {
        case loading(NativePeripheral)
        case error(NativePeripheral, String)
        case setup(NativePeripheral, UUID)
        case lock(NativePeripheral, String, PermissionType)
        case unknown(NativePeripheral, UUID)
    }
}

extension NearbyDevicesView.Item: Identifiable {
    
    var id: NativeCentral.Peripheral {
        switch self {
        case let .error(id, _):
            return id
        case let .loading(id):
            return id
        case let .setup(id, _):
            return id
        case let .lock(id, _, _):
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
        case let .error(_, error):
            self.init(
                image: .emoji("⚠️"),
                title: "Error",
                subtitle: error
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
        case let .lock(_, name, type):
            self.init(
                image: .permission(type),
                title: name,
                subtitle: type.localizedText
            )
        }
    }
}

// MARK: - Preview

#if targetEnvironment(simulator)
struct NearbyDevicesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NearbyDevicesView.StateView(
                state: .scanning,
                items: [
                    .loading(.random),
                    .error(.random, LockError.notInRange(lock: UUID()).localizedDescription),
                    .setup(.random, UUID()),
                    .unknown(.random, UUID()),
                    .lock(.random, "My lock", .admin)
                ],
                toggleScan: {  },
                destination: { Text(verbatim: $0.id.description) }
            )
        }
    }
}
#endif
