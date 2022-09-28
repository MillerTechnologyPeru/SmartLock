//
//  MessagesView.swift
//  LockMessage
//
//  Created by Alsey Coleman Miller on 9/27/22.
//

import Foundation
import Messages
import SwiftUI
import LockKit

struct MessagesView: View {
    
    @EnvironmentObject
    var store: Store
    
    var didCreateKey: (URL, NewKey.Invitation) -> ()
    
    var body: some View {
        List {
            Section("Locks") {
                ForEach(locks) { lock in
                    NavigationLink(destination: {
                        NewPermissionView(id: lock.id) { url, invitation in
                            didCreateKey(url, invitation)
                        }
                    }, label: {
                        LockRowView(lock: lock.cache)
                    })
                }
            }
        }
        .listStyle(.plain)
    }
}

private extension MessagesView {
    
    var locks: [Lock] {
        store.applicationData.locks
            .lazy
            .map { Lock(id: $0.key, cache: $0.value) }
            .sorted { $0.cache.key.created < $1.cache.key.created }
    }
    
    func select(_ lock: Lock) {
        
    }
}

internal extension MessagesView {
    
    struct Lock: Identifiable {
        
        let id: UUID
        let cache: LockCache
    }
}

internal extension LockRowView {
    
    init(lock: MessagesView.Lock) {
        self.init(
            image: .permission(lock.cache.key.permission.type),
            title: lock.cache.name,
            subtitle: lock.cache.key.permission.type.localizedText
        )
    }
}

#if DEBUG && targetEnvironment(simulator)
struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
        //MessagesView(didCreateKey: { })
    }
}
#endif
