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
    
    @State
    private var detail = AnyView(Text("Select a lock"))
    
    @State
    private var currentSubview = AnyView(EmptyView())
    
    @State
    private var showingSubview = false
    
    var body: some View {
        SwiftUI.NavigationView {
            SidebarView.NavigationView(
                selection: Binding(
                    get: { sidebarSelection },
                    set: { sidebarSelectionChanged($0) }
                ),
                isScanning: store.isScanning,
                locks: locks,
                keys: keys,
                isNearbyExpanded: Binding(
                    get: { isNearbyExpanded },
                    set: { toggleNearbyExpanded($0) }
                ),
                isKeysExpanded: $isKeysExpanded
            )
            detail
        }
        .navigationViewStyle(.columns)
        .onAppear {
            // configure navigation links
            AppNavigationLinkNavigate = {
                self.currentSubview = $0
                self.showingSubview = true
            }
            Task {
                do { try await Store.shared.syncCloud(conflicts: { _ in return true }) } // always override on macOS
                catch { log("⚠️ Unable to automatically sync with iCloud") }
            }
        }
    }
}

private extension SidebarView {
    
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
            detail = detailView(for: information.id)
        case let .key(keyID, _, _):
            guard let lock = store.applicationData.locks.first(where: { $0.value.key.id == keyID })?.key else {
                // invalid key selection
                assertionFailure("Selected unknown key \(keyID)")
                return
            }
            detail = detailView(for: lock)
        }
    }
    
    func detailView(for lock: UUID) -> AnyView {
        AnyView(StackNavigationView(
             currentSubview: $currentSubview,
             showingSubview: $showingSubview,
             rootView: {
                 LockDetailView(id: lock)
                     .toolbar {
                         ToolbarItem(placement: .navigation) {
                             Button(action: {
                                 Task {
                                     if store.isScanning {
                                         store.stopScanning()
                                     } else {
                                         await store.scan()
                                     }
                                 }
                             }, label: {
                                 if store.isScanning {
                                     Label("stop", systemImage: "stop.fill")
                                 } else {
                                     Label("scan", systemImage: "arrow.clockwise")
                                 }
                             })
                         }
                     }
             }
         ))
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
    
    struct NavigationView: View {
        
        @Binding
        var selection: Item.ID?
        
        let isScanning: Bool
        
        let locks: [Item]
        
        let keys: [Item]
        
        @Binding
        var isNearbyExpanded: Bool
        
        @Binding
        var isKeysExpanded: Bool
        
        var body: some View {
            List(selection: $selection) {
                Group(
                    title: "Nearby",
                    image: isScanning ? .loading : .symbol("antenna.radiowaves.left.and.right"),
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
        }
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
