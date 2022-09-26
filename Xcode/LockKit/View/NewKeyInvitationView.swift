//
//  NewKeyInvitationView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/21/22.
//

import SwiftUI
import CoreLock

public struct NewKeyInvitationView: View {
    
    @EnvironmentObject
    public var store: Store
    
    public let invitation: NewKey.Invitation
    
    @State
    private var activityIndicator = false
    
    @State
    private var pendingTask: TaskQueue.PendingTask?
    
    public init(invitation: NewKey.Invitation) {
        self.invitation = invitation
    }
    
    public var body: some View {
        KeyDetailView(
            key: .newKey(invitation.key),
            lock: invitation.lock
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if store.applicationData.locks[invitation.lock] == nil {
                    if activityIndicator {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Button(action: {
                            accept()
                        }, label: {
                            Text("Accept")
                        })
                    }
                }
            }
        }
    }
}

internal extension NewKeyInvitationView {
    
    func accept() {
        // request name modal
        createNewKey("My lock")
    }
    
    func createNewKey(_ name: String) {
        activityIndicator = true
        Task {
            await pendingTask?.cancel()
            await pendingTask = Task.bluetooth {
                activityIndicator = true
                defer { Task { await MainActor.run { activityIndicator = false } } }
                guard await store.central.state == .poweredOn else {
                    return
                }
                do {
                    try await store.confirm(invitation, name: name)
                } catch {
                    log("⚠️ Error creating new key for \(invitation.lock). \(error)")
                }
            }
        }
    }
}

#if DEBUG
struct NewKeyInvitationView_Previews: PreviewProvider {
    static var previews: some View {
        //NewKeyInvitationView()
        EmptyView()
    }
}
#endif
