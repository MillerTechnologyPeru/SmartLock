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
        
    var shareKey: (URL, NewKey.Invitation) -> ()
    
    var didAppear: (Bool) -> ()
    
    @State
    private var invitationFiles = [URL]()
    
    @State
    private var fileTasks = [URL: Task<Void, Never>]()
    
    @State
    private var fileErrors = [URL: Error]()
    
    var body: some View {
        if locks.isEmpty {
            AnyView(Text("No keys"))
        } else {
            AnyView(
                List {
                    Section("Share keys") {
                        ForEach(locks) { lock in
                            NavigationLink(destination: {
                                NewPermissionView(id: lock.id) { url, invitation in
                                    shareKey(url, invitation)
                                }
                            }, label: {
                                LockRowView(lock: lock.cache)
                            })
                        }
                    }
                    if newKeysFetchedResults.isEmpty == false {
                        Section("Pending Keys") {
                            ForEach(newKeys) {
                                view(for: $0)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .onAppear {
                    reload()
                    didAppear(true)
                }
                .onDisappear {
                    didAppear(false)
                }
            )
        }
    }
}

private extension MessagesView {
    
    func reload() {
        newKeysFetchedResults.reload()
    }
    
    var locks: [Lock] {
        store.applicationData.locks
            .lazy
            .sorted { $0.value.key.created < $1.value.key.created }
            .map { Lock(id: $0.key, cache: $0.value) }
    }
    
    var newKeysFetchedResults: AsyncFetchedResults<NewKeyInvitationStore.DataSource> {
        .init(dataSource: .init(store: store.newKeyInvitations), configuration: (), results: $invitationFiles, tasks: $fileTasks, errors: $fileErrors)
    }
    
    var newKeys: LazyMapSequence<AsyncFetchedResults<NewKeyInvitationStore.DataSource>, Invitation> {
        newKeysFetchedResults.lazy.map {
            switch $0 {
            case let .loading(url):
                return .init(id: url, state: .loading)
            case let .failure(url, error):
                return .init(id: url, state: .error(error.localizedDescription))
            case let .success(url, invitation):
                let name = store.applicationData.locks[invitation.lock]?.name ?? invitation.lock.uuidString
                return .init(id: url, state: .invitation(invitation, name))
            }
        }
    }
    
    func view(for item: MessagesView.Invitation) -> some View {
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
            return AnyView(
                Button(action: {
                    shareKey(item.id, invitation)
                }, label: {
                    LockRowView(
                        image: .permission(invitation.key.permission.type),
                        title: invitation.key.name,
                        subtitle: "\(lockName) - \(invitation.key.permission.localizedText)"
                    )
                })
            )
        }
    }
}

internal extension MessagesView {
    
    struct Lock: Identifiable {
        
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
