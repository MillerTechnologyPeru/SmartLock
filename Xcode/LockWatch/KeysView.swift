//
//  KeysView.swift
//  Watch App
//
//  Created by Alsey Coleman Miller on 9/28/22.
//

import SwiftUI
import LockKit

struct KeysView: View {
    
    @EnvironmentObject
    var store: Store
    
    var body: some View {
        list
            .navigationTitle("Keys")
            .onAppear {
                reload()
            }
    }
}

private extension KeysView {
    
    var list: some View {
        List {
            ForEach(locks) {
                view(for: $0)
            }
        }
    }
    
    var locks: [Lock] {
        store.applicationData.locks
            .lazy
            .sorted(by: { $0.value.key.created < $1.value.key.created })
            .map { Lock(id: $0.key, cache: $0.value) }
    }
    
    func view(for item: KeysView.Lock) -> some View {
        AppNavigationLink(id: .lock(item.id)) {
            LockRowView(
                image: .permission(item.cache.key.permission.type),
                title: item.cache.name,
                subtitle: item.cache.key.permission.type.localizedText
            )
        }
    }
    
    func reload() {
        
    }
}

extension KeysView {
    
    struct Lock: Identifiable, Equatable {
        
        let id: UUID
        let cache: LockCache
    }
}

#if DEBUG
struct KeysView_Previews: PreviewProvider {
    static var previews: some View {
        KeysView()
    }
}
#endif
