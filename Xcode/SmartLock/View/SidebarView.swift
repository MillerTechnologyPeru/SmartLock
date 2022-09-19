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
            Text(verbatim: "Select a lock\n\(selection?.description ?? "")")
        }
    }
}

private extension SidebarView {
    
    var peripherals: [NativePeripheral] {
        store.peripherals.keys.sorted(by: { $0.id.description < $1.id.description })
    }
    
    var locks: [Item] {
        peripherals.map {
            .lock($0.id, "Lock \($0)", .admin)
        }
    }
    
    var keys: [Item] {
        [
            .key(UUID(), "Key1", .admin)
        ]
    }
    
    func toggleNearbyExpanded(_ newValue: Bool) {
        isNearbyExpanded = newValue
        // start scanning if not already
        if newValue, !store.isScanning {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await store.scan()
            }
        } else if !newValue, store.isScanning {
            store.stopScanning()
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
        case lock(NativePeripheral.ID, String, PermissionType)
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
            self.init(title: title, image: .permission(permission))
        case let .key(_, title, permission):
            self.init(title: title, image: .permission(permission))
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
