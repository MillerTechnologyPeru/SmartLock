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
    
    @State
    private var invitationFiles = [URL]()
    
    @State
    private var fileTasks = [URL: Task<Void, Never>]()
    
    @State
    private var fileErrors = [URL: Error]()
    
    var body: some View {
        StateView(
            locks: locks,
            newKeys: newKeys.lazy.map({
                switch $0 {
                case let .loading(url):
                    return .init(id: url, state: .loading)
                case let .failure(url, error):
                    return .init(id: url, state: .error(error.localizedDescription))
                case let .success(url, invitation):
                    let name = store.applicationData.locks[invitation.lock]?.name ?? invitation.lock.uuidString
                    return .init(id: url, state: .invitation(invitation, name))
                }
            }),
            deleteNewKey: deleteNewKey
        )
        .onAppear {
            reload()
        }
    }
}

private extension KeysView {
    
    var locks: [Lock] {
        store.applicationData.locks
            .lazy
            .sorted(by: { $0.value.key.created < $1.value.key.created })
            .map { Lock(id: $0.key, cache: $0.value) }
    }
    
    var newKeys: AsyncFetchedResults<NewKeyInvitationStore.DataSource> {
        .init(dataSource: .init(store: store.newKeyInvitations), configuration: (), results: $invitationFiles, tasks: $fileTasks, errors: $fileErrors)
    }
    
    func deleteNewKey(_ url: URL) {
        log("Delete \(url)")
    }
    
    func reload() {
        newKeys.reload()
    }
}

extension KeysView {
    
    struct StateView <NewKeys> : View where NewKeys: RandomAccessCollection, NewKeys.Element == Invitation {
        
        let locks: [Lock]
        
        let newKeys: NewKeys
        
        let deleteNewKey: (URL) -> ()
        
        var body: some View {
            list.navigationTitle("Keys")
        }
    }
}

private extension KeysView.StateView {
    
    var list: some View {
        List {
            ForEach(locks) {
                view(for: $0)
            }
            if newKeys.isEmpty == false {
                Section("Pending") {
                    ForEach(newKeys) {
                        view(for: $0)
                    }
                    .onDelete { deleteNewKey(for: $0) }
                }
            }
        }
    }
    
    func deleteNewKey(for indexPath: IndexSet) {
        //newKeys[indexPath[0]]
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
    
    func view(for item: KeysView.Invitation) -> some View {
        switch item.state {
        case .loading:
            return AnyView(
                LockRowView(
                    image: .loading,
                    title: NSLocalizedString("Loading...", comment: "")
                )
            )
        case let .error(error):
            return AnyView(
                LockRowView(
                    image: .emoji("⚠️"),
                    title: "Unable to load \(item.id.lastPathComponent).",
                    subtitle: error
                )
            )
        case let .invitation(invitation, lockName):
            return AnyView(AppNavigationLink(id: .newKeyInvitation(invitation)) {
                LockRowView(
                    image: .permission(invitation.key.permission.type),
                    title: invitation.key.name,
                    subtitle: "\(lockName) - \(invitation.key.permission.localizedText)"
                )
            })
        }
    }
}

extension KeysView {
    
    struct Lock: Identifiable, Equatable {
        
        let id: UUID
        let cache: LockCache
    }
    
    struct Invitation: Identifiable {
        
        let id: URL
        let state: InvitationState
    }
    
    enum InvitationState {
        case loading
        case invitation(NewKey.Invitation, String)
        case error(String)
    }
}

// MARK: - Preview

#if DEBUG
struct KeysView_Previews: PreviewProvider {
    
    static var previews: some View {
        PreviewView(
            locks: [
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
            ],
            newKeys: [
                .init(
                    id: URL(fileURLWithPath: "/tmp/newKey-\(UUID()).ekey"),
                    state: .loading
                ),
                .init(
                    id: URL(fileURLWithPath: "/tmp/newKey-\(UUID(uuidString: "879F5EF6-2369-47B4-9A6D-F2413C06EF14")!).ekey"),
                    state: .invitation(try! JSONDecoder().decode(NewKey.Invitation.self, from: Data(#"{"key":{"id":"879F5EF6-2369-47B4-9A6D-F2413C06EF14","created":685436924.88646305,"name":"Anytime Key","permission":{"type":"anytime"},"expiration":685523324.88646305},"lock":"DD944B0B-3C40-4524-9C71-7A7FE23DCB8D","secret":"dgARK0MXd4Em6IcuRUUItrq3rZcAPcpSQ5LwzzM3c9I="}"#.utf8)), "My lock")
                ),
                .init(
                    id: URL(fileURLWithPath: "/tmp/newKey-\(UUID()).ekey"),
                    state: .loading
                ),
                .init(
                    id: URL(fileURLWithPath: "/tmp/newKey-\(UUID()).ekey"),
                    state: .error("Unable to read file.")
                )
            ]
        )
    }
    
    struct PreviewView: View {
        
        @State
        var locks: [KeysView.Lock]
        
        @State
        var newKeys: [KeysView.Invitation]
        
        var body: some View {
            NavigationView {
                KeysView.StateView(
                    locks: locks,
                    newKeys: newKeys,
                    deleteNewKey: { url in
                        if let index = newKeys.firstIndex(where: { $0.id == url }) {
                            newKeys.remove(at: index)
                        }
                    }
                )
                .refreshable {
                    Task {
                        try await Task.sleep(timeInterval: 1.0)
                        newKeys[0] = .init(
                            id: URL(fileURLWithPath: "/tmp/newKey-\(UUID(uuidString: "879F5EF6-2369-47B4-9A6D-F2413C06EF14")!).ekey"),
                            state: .invitation(try! JSONDecoder().decode(NewKey.Invitation.self, from: Data(#"{"key":{"id":"879F5EF6-2369-47B4-9A6D-F2413C06EF14","created":685436924.88646305,"name":"Anytime Key","permission":{"type":"anytime"},"expiration":685523324.88646305},"lock":"DD944B0B-3C40-4524-9C71-7A7FE23DCB8D","secret":"dgARK0MXd4Em6IcuRUUItrq3rZcAPcpSQ5LwzzM3c9I="}"#.utf8)), "My lock")
                        )
                    }
                }
            }
        }
    }
}
#endif
