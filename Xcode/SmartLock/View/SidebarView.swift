//
//  Sidebar.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

#if os(macOS)
import SwiftUI
import LockKit

struct SidebarView: View {
    
    @EnvironmentObject
    var store: Store
    
    @State
    private var sidebarSelection: Item.ID?
    
    @State
    private var isNearbyExpanded = true
    
    @State
    private var isKeysExpanded = true
    
    @StateObject
    var coordinator = AppNavigationLinkCoordinator()
    
    var body: some View {
        NavigationView {
            SidebarNavigationView(
                selection: Binding(
                    get: { sidebarSelection },
                    set: { sidebarSelectionChanged($0) }
                ),
                scanStatus: scanStatus,
                locks: locks,
                keys: keys,
                isNearbyExpanded: Binding(
                    get: { isNearbyExpanded },
                    set: { toggleNearbyExpanded($0) }
                ),
                isKeysExpanded: $isKeysExpanded,
                toggleScan: toggleScan
            )
            if navigationStack.count > 0 {
                navigationStack[0].view
            }
            if navigationStack.count > 1 {
                navigationStack[1].view
            }
        }
        .navigationViewStyle(.columns)
        .frame(minWidth: 550, minHeight: 550)
        .onAppear {
            Task {
                do { try await Store.shared.syncCloud(conflicts: { _ in return true }) } // always override on macOS
                catch { log("⚠️ Unable to automatically sync with iCloud. \(error)") }
            }
        }
        .environmentObject(coordinator)
        
    }
}

private extension SidebarView {
    
    var scanStatus: ScanStatus {
        if store.isScanning {
            return .scanning
        } else if store.state != .poweredOn {
            return .bluetoothUnavailable
        } else {
            return .stopScan
        }
    }
    
    var peripherals: [NativePeripheral] {
        store.peripherals.keys.sorted(by: { $0.id.description < $1.id.description })
    }
    
    var locks: [Item] {
        peripherals.map { item(for: $0) }
    }
    
    var keys: [Item] {
        store.applicationData.locks.values
            .lazy
            .sorted(by: { $0.key.created < $1.key.created })
            .map { .key($0.key.id, $0.name, $0.key.permission.type) }
    }
    
    func toggleScan() {
        if store.isScanning {
            store.stopScanning()
        } else {
            Task {
                //await scanTask?.cancel()
                await TaskQueue.bluetooth.cancelAll() // stop all pending operations to scan
                await Task.bluetooth {
                    guard await store.central.state == .poweredOn,
                          store.isScanning == false else {
                        return
                    }
                    await store.scan()
                }
            }
        }
    }
    
    func toggleNearbyExpanded(_ newValue: Bool) {
        isNearbyExpanded = newValue
        // start scanning if not already
        if newValue, !store.isScanning {
            store.peripherals.removeAll(keepingCapacity: true)
            store.isScanning = true
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await store.scan()
            }
        } else if !newValue, store.isScanning {
            store.stopScanning()
        }
    }
    
    var navigationStack: [(id: AppNavigationLinkID, view: AnyView)] {
        guard let current = coordinator.current else {
            return []
        }
        switch current.id {
        case let .lock(lock):
            return [current, (.events(lock), AnyView(EventsView(lock: lock)))]
        case let .events(lock):
            return [(.lock(lock), AnyView(LockDetailView(id: lock))), current]
        case let .permissions(lock):
            return [(.lock(lock), AnyView(LockDetailView(id: lock))), current]
        default:
            return [current]
        }
    }
    
    func sidebarSelectionChanged(_ newValue: Item.ID?) {
        sidebarSelection = newValue
        // deselect
        Task {
            try? await Task.sleep(timeInterval: 0.5)
            sidebarSelection = nil
        }
        guard let sidebarSelection = newValue else {
            return // no effect if deselect
        }
        guard let item = locks.first(where: { $0.id == sidebarSelection }) ?? keys.first(where: { $0.id == sidebarSelection }) else {
            return
        }
        // try to show cached lock
        switch item {
        case let .lock(peripheralID, _, _):
            guard let peripheral = store.peripherals.keys.first(where: { $0.id == peripheralID }) else {
                return
            }
            guard let information = store.lockInformation[peripheral] else {
                // cannot select loading locks
                return
            }
            let lock = information.id
            coordinator.current = (.lock(lock), detailView(for: lock))
        case let .key(keyID, _, _):
            guard let lock = store.applicationData.locks.first(where: { $0.value.key.id == keyID })?.key else {
                // invalid key selection
                assertionFailure("Selected unknown key \(keyID)")
                return
            }
            coordinator.current = (.lock(lock), detailView(for: lock))
        }
    }
    
    func detailView(for lock: UUID) -> AnyView {
        return AnyView(
            LockDetailView(id: lock)
        )
    }
    
    func item(for peripheral: NativePeripheral) -> Item {
        if let information = store.lockInformation[peripheral] {
            switch information.status {
            case .setup:
                //return .setup(peripheral.id, information.id)
                return .lock(peripheral.id, "Setup", .owner)
            default:
                if let lockCache = store[lock: information.id] {
                    //return .key(peripheral.id, lockCache.name, lockCache.key.permission.type)
                    return .lock(peripheral.id, lockCache.name, lockCache.key.permission.type)
                } else {
                    //return .unknown(peripheral.id, information.id)
                    return .lock(peripheral.id, "Lock", .anytime)
                }
            }
        } else {
            //return .loading(peripheral.id)
            return .lock(peripheral.id, "Loading...", nil)
        }
    }
    
    var selectionDetail: AnyView {
        guard let selection = self.sidebarSelection, let item = locks.first(where: { $0.id == selection }) ?? keys.first(where: { $0.id == selection }) else {
            return AnyView(
                Text("Select a lock")
            )
        }
        switch item {
        case let .lock(id, _, _):
            // FIXME: store peripheral instead of id
            guard let peripheral = store.peripherals.keys.first(where: { $0.id == id }) else {
                return AnyView(
                    Text("Select a lock")
                )
            }
            guard let information = store.lockInformation[peripheral] else {
                return AnyView(
                    ProgressView()
                        .progressViewStyle(.circular)
                )
            }
            return AnyView(LockDetailView(id: information.id))
        case let .key(id, _, _):
            guard let lock = store.applicationData.locks.first(where: { $0.value.key.id == id })?.key else {
                return AnyView(
                    Text("Select a lock")
                )
            }
            return AnyView(LockDetailView(id: lock))
        }
    }
}

extension SidebarView {
    
    struct SidebarNavigationView: View {
        
        @Binding
        var selection: Item.ID?
        
        let scanStatus: ScanStatus
        
        let locks: [Item]
        
        let keys: [Item]
        
        @Binding
        var isNearbyExpanded: Bool
        
        @Binding
        var isKeysExpanded: Bool
        
        var toggleScan: () -> ()
        
        var body: some View {
            List(selection: $selection) {
                Group(
                    title: "Nearby",
                    image: scanStatus == .scanning ? .loading : .symbol("antenna.radiowaves.left.and.right"),
                    items: locks,
                    isExpanded: $isNearbyExpanded
                )
                Group(
                    title: "Keys",
                    image: .symbol("key"),
                    items: keys,
                    isExpanded: $isKeysExpanded
                )
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    scanButton
                }
            }
        }
    }
}

private extension SidebarView.SidebarNavigationView {
    
    var scanButton: some View {
        Button(action: {
            toggleScan()
        }, label: {
            switch scanStatus {
            case .bluetoothUnavailable:
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
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

extension SidebarView {
    
    enum ScanStatus {
        case bluetoothUnavailable
        case scanning
        case stopScan
    }
}

extension SidebarView {
    
    struct Group: View {
                
        let title: String
        
        let image: SidebarLabel.Image
        
        let items: [Item]
        
        let isExpanded: Binding<Bool>
        
        var body: some View {
            DisclosureGroup(isExpanded: isExpanded, content: {
                ForEach(items) {
                    SidebarLabel($0)
                }
            }, label: {
                SidebarLabel(title: title, image: image)
            })
        }
    }
}

// MARK: - Supporting Types

extension SidebarView {
    
    enum Item {
        case lock(NativePeripheral.ID, String, PermissionType?)
        case key(UUID, String, PermissionType)
    }
}

extension SidebarView.Item: Identifiable {
    
    var id: String {
        switch self {
        case let .lock(id, _, _):
            return "lock_" + id.description
        case let .key(id, _, _):
            return "key_" + id.description
        }
    }
}

extension SidebarLabel {
    
    init(_ item: SidebarView.Item) {
        switch item {
        case let .lock(_, title, permission):
            self.init(
                title: title,
                image: permission.flatMap { .permission($0) } ?? .loading
            )
        case let .key(_, title, permission):
            self.init(
                title: title,
                image: .permission(permission)
            )
        }
    }
}

// MARK: - Preview

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
#endif
