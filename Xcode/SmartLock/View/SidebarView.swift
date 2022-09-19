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
    var selection: Item.ID?
    
    @State
    private var isNearbyExpanded = true
    
    @State
    private var isKeysExpanded = true
    
    var body: some View {
        SwiftUI.NavigationView {
            SidebarView.NavigationView(
                selection: $selection,
                isScanning: store.isScanning,
                locks: locks,
                keys: keys,
                isNearbyExpanded: Binding(
                    get: { isNearbyExpanded },
                    set: { toggleNearbyExpanded($0) }
                ),
                isKeysExpanded: $isKeysExpanded
            )
            DetailView(state: detail)
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
            .map { $0.key }
            .sorted(by: { $0.created < $1.created })
            .map { .key($0.id, $0.name, $0.permission.type) }
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
    
    var detail: DetailView.State {
        guard let selection = self.selection, let item = locks.first(where: { $0.id == selection }) ?? keys.first(where: { $0.id == selection }) else {
            return .empty
        }
        switch item {
        case let .lock(id, _, _):
            // FIXME: store peripheral instead of id
            guard let peripheral = store.peripherals.keys.first(where: { $0.id == id }) else {
                return .empty
            }
            return .lock(peripheral)
        case let .key(id, _, _):
            return .key(id)
        }
    }
}

extension SidebarView {
    
    struct DetailView: View {
        
        let state: State
        
        var body: some View {
            switch state {
            case .empty:
                AnyView(
                    Text("Select a lock")
                )
            case let .lock(peripheral):
                AnyView(
                    Text(verbatim: "Lock \(peripheral)")
                )
            case let .key(id):
                AnyView(
                    Text(verbatim: "Key \(id)")
                )
            }
        }
    }
}

extension SidebarView.DetailView {
    
    enum State {
        case empty
        case lock(NativePeripheral)
        case key(UUID)
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
