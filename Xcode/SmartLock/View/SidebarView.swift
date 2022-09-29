//
//  Sidebar.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

#if os(macOS)
import SwiftUI
import LockKit
import SFSafeSymbols

struct SidebarView: View {
    
    @EnvironmentObject
    var store: Store
    
    @State
    private var sidebarSelection: Item.ID?
    
    @State
    private var isNearbyExpanded = true
    
    @State
    private var isKeysExpanded = true
    
    @State
    private var isEventsExpanded = true
    
    @State
    private var isNewKeysExpanded = true
    
    @State
    private var detail: AnyView = AnyView(Text("Select a lock"))
    
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
                events: events,
                isNearbyExpanded: Binding(
                    get: { isNearbyExpanded },
                    set: { toggleNearbyExpanded($0) }
                ),
                isKeysExpanded: $isKeysExpanded,
                isEventsExpanded: $isEventsExpanded,
                isNewKeysExpanded: $isNewKeysExpanded,
                toggleScan: toggleScan
            )
            NavigationStack {
                detail
                .navigationDestination(for: AppNavigationLinkID.self) {
                    AppNavigationDestinationView(id: $0)
                }
            }
        }
        .navigationViewStyle(.columns)
        .frame(minWidth: 550, minHeight: 550)
        .onAppear {
            Task {
                do { try await store.forceDownloadCloudApplicationData() } // always override on macOS
                catch { log("⚠️ Unable to automatically sync with iCloud. \(error.localizedDescription)") }
            }
            Task {
                try await store.central.wait(for: .poweredOn)
                store.scan(duration: store.preferences.scanDuration)
            }
        }
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
    
    var events: [Item] {
        [] // FIXME: Events
    }
    
    func toggleScan() {
        if store.isScanning {
            store.stopScanning()
        } else {
            store.scanDefault()
        }
    }
    
    func toggleNearbyExpanded(_ newValue: Bool) {
        isNearbyExpanded = newValue
        // start scanning if not already
        if newValue, !store.isScanning {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                store.scanDefault()
            }
        } else if !newValue, store.isScanning {
            store.stopScanning()
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
            detail = AnyView(detailView(for: lock))
        case let .key(keyID, _, _):
            guard let lock = store.applicationData.locks.first(where: { $0.value.key.id == keyID })?.key else {
                // invalid key selection
                assertionFailure("Selected unknown key \(keyID)")
                return
            }
            detail = AnyView(detailView(for: lock))
        case let .events(lock, predicate, _):
            detail = AnyView(EventsView(lock: lock, predicate: predicate))
        }
    }
    
    func detailView(for lock: UUID) -> some View {
        LockDetailView(id: lock)
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
}

extension SidebarView {
    
    struct SidebarNavigationView: View {
        
        @Binding
        var selection: Item.ID?
        
        let scanStatus: ScanStatus
        
        let locks: [Item]
        
        let keys: [Item]
        
        let events: [Item]
        
        @Binding
        var isNearbyExpanded: Bool
        
        @Binding
        var isKeysExpanded: Bool
        
        @Binding
        var isEventsExpanded: Bool
        
        @Binding
        var isNewKeysExpanded: Bool
        
        var toggleScan: () -> ()
        
        var body: some View {
            List(selection: $selection) {
                Group(
                    title: "Nearby",
                    image: scanStatus == .scanning ? .loading : .symbol(.antennaRadiowavesLeftAndRight), //"antenna.radiowaves.left.and.right"
                    items: locks,
                    isExpanded: $isNearbyExpanded
                )
                Group(
                    title: "Keys",
                    image: .symbol(.key),
                    items: keys,
                    isExpanded: $isKeysExpanded
                )
                Group(
                    title: "Invitations",
                    image: .symbol(.envelope),
                    items: [],
                    isExpanded: $isNewKeysExpanded
                )
                Group(
                    title: "History",
                    image: .symbol(.clock),
                    items: events,
                    isExpanded: $isEventsExpanded
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
        //case newKey(URL)
        case events(UUID?, LockEvent.Predicate?, String)
    }
}

extension SidebarView.Item: Identifiable {
    
    var id: String {
        switch self {
        case let .lock(id, _, _):
            return "lock_" + id.description
        case let .key(id, _, _):
            return "key_" + id.description
        case let .events(lock, predicate, _):
            if lock == nil, predicate == nil {
                return "event_\(lock?.description ?? "")\(predicate.map { String(describing: $0) } ?? "")"
            } else {
                return "events_all"
            }
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
        case let .events(_, _, name):
            self.init(title: name, image: .symbol(.clock))
        }
    }
}

// MARK: - Preview

#if DEBUG
struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
#endif
#endif
