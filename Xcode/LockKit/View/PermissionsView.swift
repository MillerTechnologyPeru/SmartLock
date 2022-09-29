//
//  PermissionsView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/20/22.
//

import SwiftUI
import CoreLock

public struct PermissionsView: View {
    
    @EnvironmentObject
    public var store: Store
    
    @Environment(\.managedObjectContext)
    public var managedObjectContext
    
    @StateObject
    public var fileStore: NewKeyInvitationStore = Store.shared.newKeyInvitations
    
    /// Identifier of lock
    public let id: UUID
        
    @FetchRequest(
        entity: KeyManagedObject.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \KeyManagedObject.created, ascending: false)
        ],
        predicate: nil,
        animation: .linear
    )
    private var keys: FetchedResults<KeyManagedObject>
    
    @FetchRequest(
        entity: NewKeyManagedObject.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \NewKeyManagedObject.created, ascending: false)
        ],
        predicate: nil,
        animation: .linear
    )
    private var newKeys: FetchedResults<NewKeyManagedObject>
    
    fileprivate static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()

    fileprivate static let timeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    fileprivate static let relativeDateTimeFormatter: RelativeDateTimeFormatter = {
        let dateFormatter = RelativeDateTimeFormatter()
        dateFormatter.dateTimeStyle = .numeric
        dateFormatter.unitsStyle = .spellOut
        return dateFormatter
    }()
    
    @State
    private var activityIndicator = false
    
    @State
    private var reloadTask: TaskQueue.PendingTask?
    
    @State
    private var showNewKeyModal = false
    
    public var body: some View {
        StateView(
            lock: id,
            keys: keys.lazy.compactMap { Key(managedObject: $0) },
            newKeys: newKeys.lazy.compactMap { NewKey(managedObject: $0) },
            invitations: invitations,
            reload: reload,
            deleteKeys: deleteKeys,
            deleteNewKeys: deleteNewKeys
        )
        .onAppear {
            self.keys.nsPredicate = predicate
            self.newKeys.nsPredicate = predicate
        }
        .onDisappear {
            Task {
                await self.reloadTask?.cancel()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if canCreateNewKey {
                    Button(action: newPermission, label: {
                        Image(systemSymbol: .plus)
                    })
                }
            }
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                if activityIndicator {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            #endif
        }
        .newPermissionSheet(
            for: id,
            isPresented: $showNewKeyModal,
            onDismiss: { },
            completion: didCreateNewKey
        )
    }
    
    public init(id: UUID) {
        self.id = id
    }
}

private extension PermissionsView {
    
    var predicate: NSPredicate {
        NSPredicate(
            format: "%K == %@",
            #keyPath(KeyManagedObject.lock.identifier),
            id as NSUUID
        )
    }
    
    var invitations: [UUID: URL] {
        let cache = fileStore.cache
        var invitations = [UUID: URL]()
        invitations.reserveCapacity(cache.count)
        for (url, invitation) in cache {
            invitations[invitation.key.id] = url
        }
        return invitations
    }
    
    func reload() {
        activityIndicator = true
        Task {
            await reloadTask?.cancel()
            reloadTask = await Task.bluetooth {
                activityIndicator = true
                defer { Task { await MainActor.run { activityIndicator = false } } }
                guard await store.central.state == .poweredOn else {
                    return
                }
                do {
                    if store.isScanning {
                        store.stopScanning()
                    }
                    guard let peripheral = try await store.device(for: id) else {
                        // unable to find device
                        return
                    }
                    try await store.listKeys(for: peripheral)
                } catch {
                    log("⚠️ Error loading keys for \(id). \(error)")
                }
            }
            Task {
                do {
                    let urls = try fileStore.fetchDocuments()
                    for url in urls {
                        guard fileStore.cache[url] == nil,
                              let invitation = try? await fileStore.load(url) else {
                            continue
                        }
                        log("Loaded key \(invitation.key.name) \(invitation.lock) at \(url.lastPathComponent)")
                    }
                } catch {
                    log("⚠️ Error loading pending keys invitations. \(error)")
                    assertionFailure()
                }
            }
        }
    }
    
    var canCreateNewKey: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return store[lock: id]?.key.permission.isAdministrator ?? false
        #endif
    }
    
    func newPermission() {
        showNewKeyModal = true
    }
    
    func didCreateNewKey(url: URL, invitation: NewKey.Invitation) {
        // hide modal
        showNewKeyModal = false
        // reload
        Task {
            try? await Task.sleep(timeInterval: 0.2)
            // reload pending keys
            reload()
        }
    }
    
    func deleteKeys(_ keys: [Key]) {
        
    }
    
    func deleteNewKeys(_ keys: [NewKey]) {
        
    }
}

internal extension PermissionsView {
    
    struct StateView <Keys, NewKeys> : View where Keys: RandomAccessCollection, Keys.Element == Key, Keys.Index == Int, NewKeys: RandomAccessCollection, NewKeys.Element == NewKey, NewKeys.Index == Int {
        
        let lock: UUID
        
        let keys: Keys
        
        let newKeys: NewKeys
        
        let invitations: [UUID: URL]
        
        let reload: () -> ()
        
        let deleteKeys: ([Key]) -> ()
        
        let deleteNewKeys: ([NewKey]) -> ()
        
        var body: some View {
            List {
                ForEach(keys) {
                    row(for: $0)
                }
                .onDelete(perform: deleteKey)
                if newKeys.isEmpty == false {
                    Section("Pending") {
                        ForEach(newKeys) {
                            row(for: $0, invitationURL: invitations[$0.id])
                        }
                        .onDelete(perform: deleteNewKey)
                    }
                }
            }
            .navigationTitle("Permissions")
            .refreshable {
                reload()
            }
            .onAppear {
                reload()
            }
        }
    }
}

private extension PermissionsView.StateView {
    
    func row(for item: Key) -> some View {
        #if os(watchOS)
        AppNavigationLink(id: .key(lock, .key(item)), label: {
            LockRowView(
                image: .permission(item.permission.type),
                title: item.name,
                subtitle: item.permission.localizedText
            )
        })
        #else
        AppNavigationLink(id: .key(lock, .key(item)), label: {
            LockRowView(
                image: .permission(item.permission.type),
                title: item.name,
                subtitle: item.permission.localizedText,
                trailing: (
                    PermissionsView.dateFormatter.string(from: item.created),
                    PermissionsView.timeFormatter.string(from: item.created)
                )
            )
        })
        #endif
    }
    
    func row(for item: NewKey, invitationURL: URL?) -> some View {
        AppNavigationLink(id: .key(lock, .newKey(item)), label: {
            HStack(alignment: .center, spacing: 8) {
                row(for: item, showDate: invitationURL == nil)
                #if !os(tvOS)
                if let url = invitationURL {
                    Spacer()
                    if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
                        AnyView(
                            ShareLink(
                                item: url,
                                subject: Text("\(item.name)"),
                                message: Text("Share this key"),
                                preview: SharePreview(
                                    item.name,
                                    icon: Image(permissionType: item.permission.type)
                                ),
                                label: { shareImage }
                            )
                            .buttonStyle(.plain)
                        )
                    } else {
                        AnyView(Button(action: {
                            
                        }, label: { shareImage }))
                        .buttonStyle(.plain)
                    }
                }
                #endif
            }
        })
    }
    
    func row(for item: NewKey, showDate: Bool) -> some View {
        #if os(watchOS)
        LockRowView(
            image: .permission(item.permission.type),
            title: item.name,
            subtitle: item.permission.localizedText + "\n" + "Expires " + PermissionsView.relativeDateTimeFormatter.localizedString(for: item.expiration, relativeTo: Date())
        )
        #else
        LockRowView(
            image: .permission(item.permission.type),
            title: item.name,
            subtitle: item.permission.localizedText + "\n" + "Expires " + PermissionsView.relativeDateTimeFormatter.localizedString(for: item.expiration, relativeTo: Date()),
            trailing: showDate ? (
                PermissionsView.dateFormatter.string(from: item.created),
                PermissionsView.timeFormatter.string(from: item.created)
            ) : nil
        )
        #endif
    }
    
    var shareImage: some View {
        Image(systemSymbol: .squareAndArrowUp)
            .foregroundColor(.blue)
            .padding(8)
    }
    
    func deleteKey(at indexSet: IndexSet) {
        let keys = indexSet.map { self.keys[$0] }
        deleteKeys(keys)
    }
    
    func deleteNewKey(at indexSet: IndexSet) {
        let files = indexSet.map { self.newKeys[$0] }
        deleteNewKeys(files)
    }
}

// MARK: - Preview

#if DEBUG
struct PermissionsView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            PermissionsView.StateView(
                lock: UUID(),
                keys: [
                    Key(
                        id: UUID(),
                        name: "Owner",
                        created: Date() - 60 * 60 * 24,
                        permission: .owner
                    ),
                    Key(
                        id: UUID(),
                        name: "Key 1",
                        created: Date() - 60 * 60 * 6,
                        permission: .admin
                    ),
                    Key(
                        id: UUID(),
                        name: "Key 2",
                        created: Date() - 60 * 60 * 6,
                        permission: .anytime
                    ),
                    Key(
                        id: UUID(),
                        name: "Key 3",
                        created: Date() - 60 * 60 * 6,
                        permission: .scheduled(
                            Permission.Schedule(
                                expiry: Date() + 60 * 60 * 24 * 150,
                                interval: .default,
                                weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday]
                            )
                        )
                    )
                ],
                newKeys: [
                    NewKey(
                        id: UUID(uuidString: "ED6DE87A-D0AF-421B-912D-3400A60EB294")!,
                        name: "Anytime Key",
                        permission: .anytime,
                        created: Date() - 60 * 60 * 2,
                        expiration: Date() + (60 * 60 * 24 * 1) + 10
                    )
                ],
                invitations: [
                    UUID(uuidString: "ED6DE87A-D0AF-421B-912D-3400A60EB294")! :
                        URL(fileURLWithPath: "/tmp/newKey-\(UUID(uuidString: "ED6DE87A-D0AF-421B-912D-3400A60EB294")!).ekey")
                ],
                reload: { },
                deleteKeys: { _ in },
                deleteNewKeys: { _ in }
            )
        }
    }
}
#endif
