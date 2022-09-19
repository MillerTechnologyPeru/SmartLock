//
//  LockDetailView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/19/22.
//

import SwiftUI
import CoreLock

public struct LockDetailView: View {
        
    @EnvironmentObject
    public var store: Store
    
    public let id: UUID
    
    public var body: some View {
        if let cache = self.cache {
            AnyView(
                StateView(
                    id: id,
                    cache: cache,
                    unlock: unlock
                )
            )
        } else {
            AnyView(UnknownView(id: id, information: information))
        }
    }
    
    public init(id: UUID) {
        self.id = id
    }
}

private extension LockDetailView {
    
    var cache: LockCache? {
        store[lock: id]
    }
    
    var information: LockInformation? {
        store.lockInformation.first(where: { $0.value.id == id })?.value
    }
    
    func unlock() {
        Task {
            //store.unlock(for:action:)
        }
    }
}

extension LockDetailView {
    
    struct StateView: View {
        
        let id: UUID
        
        let cache: LockCache
        
        let unlock: () -> ()
        
        public var body: some View {
            List {
                VStack {
                    // unlock button
                    Button(action: unlock, label: {
                        PermissionIconView(permission: cache.key.permission.type)
                            .frame(width: 150, height: 150, alignment: .center)
                    })
                    // info
                    Text(verbatim: id.description)
                }
            }
            .navigationTitle(Text(verbatim: cache.name))
        }
    }
}

extension LockDetailView {
    
    struct UnknownView: View {
        
        let id: UUID
        
        let information: LockInformation?
        
        var body: some View {
            VStack {
                Text(verbatim: id.description)
            }
        }
    }
}

// MARK: - Preview

struct LockDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                LockDetailView.StateView(
                    id: UUID(),
                    cache: LockCache(
                        key: Key(
                            id: UUID(),
                            name: "Key 1",
                            created: Date(),
                            permission: .admin
                        ),
                        name: "Home",
                        information: LockCache.Information(
                            buildVersion: .current,
                            version: .current,
                            status: .unlock,
                            unlockActions: [.default]
                        )
                    ),
                    unlock: { }
                )
            }
        }
    }
}
