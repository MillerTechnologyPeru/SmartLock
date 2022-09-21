//
//  KeysView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/19/22.
//

import SwiftUI
import LockKit

struct KeysView: View {
    
    @EnvironmentObject
    var store: Store
    
    var body: some View {
        StateView(items: items)
    }
}

private extension KeysView {
    
    var items: [Item] {
        store.applicationData.locks
            .lazy
            .sorted(by: { $0.value.key.created < $1.value.key.created })
            .map { Item(id: $0.key, cache: $0.value) }
    }
}

extension KeysView {
    
    struct StateView: View {
        
        let items: [Item]
        
        var body: some View {
            list
                .navigationTitle("Keys")
        }
    }
}

private extension KeysView.StateView {
    
    var list: some View {
        List(items) { (item) in
            AppNavigationLink(id: "lock-\(item.id)", destination: {
                LockDetailView(id: item.id)
            }, label: {
                LockRowView(item)
            })
        }
    }
}

extension KeysView {
    
    struct Item: Identifiable, Equatable {
        
        let id: UUID
        
        let cache: LockCache
    }
}

extension LockRowView {
    
    init(_ item: KeysView.Item) {
        self.init(
            image: .permission(item.cache.key.permission.type),
            title: item.cache.name,
            subtitle: item.cache.key.permission.type.localizedText
        )
    }
}

// MARK: - Preview

#if DEBUG
struct KeysView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            KeysView.StateView(items: [
                .init(
                    id: UUID(),
                    cache: LockCache(
                        key: Key(permission: .owner),
                        name: "My Lock",
                        information: LockCache.Information(
                            buildVersion: .current,
                            version: .current,
                            status: .unlock,
                            unlockActions: [.default]
                        )
                    )
                ),
                .init(
                    id: UUID(),
                    cache: LockCache(
                        key: Key(permission: .admin),
                        name: "Key 2",
                        information: LockCache.Information(
                            buildVersion: .current,
                            version: .current,
                            status: .unlock,
                            unlockActions: [.default]
                        )
                    )
                )
            ])
        }
    }
}
#endif
