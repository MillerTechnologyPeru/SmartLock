//
//  LockDetailView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/19/22.
//

import SwiftUI
import CoreLock
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

public struct LockDetailView: View {
        
    @EnvironmentObject
    public var store: Store
    
    @Environment(\.managedObjectContext)
    public var managedObjectContext
    
    public let id: UUID
    
    @State
    private var activityIndicator = false
    
    @State
    private var pendingTask: Task<Void, Never>?
    
    @State
    private var showNewKeyModal = false
    
    @State
    private var error: Error?
    
    public init(id: UUID) {
        self.id = id
    }
    
    public var body: some View {
        if let cache = self.cache {
            AnyView(
                StateView(
                    id: id,
                    cache: cache,
                    events: events,
                    keys: keys,
                    newKeys: newKeys,
                    unlock: unlock
                )
                .refreshable {
                    reload()
                }
                .onAppear {
                    reload()
                }
                .onDisappear {
                    pendingTask?.cancel()
                    pendingTask = nil
                }
                .alert(error: $error)
                .newPermissionSheet(
                    for: id,
                    isPresented: $showNewKeyModal,
                    onDismiss: { },
                    completion: didCreateNewKey
                )
                .toolbar {
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if activityIndicator {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                    #endif
                    /*
                    #if os(iOS) || os(macOS)
                    ToolbarItem(placement: .primaryAction) {
                        Image(systemSymbol: .ellipsisCircleFill)
                            .contextMenu {
                                if cache.key.permission.isAdministrator {
                                    Button(action: {
                                        newPermission()
                                    }, label: {
                                        Label("Share Key", systemSymbol: .plus)
                                    })
                                }
                                Button(action: {
                                    
                                }, label: {
                                    Label("Rename", systemSymbol: .pencil)
                                })
                                Button(action: {
                                    
                                }, label: {
                                    Label("Delete", systemSymbol: .delete)
                                })
                            }
                    }
                    #endif*/
                }
            )
        } else if let information = self.information,
            information.status == .setup {
            AnyView(SetupLockView())
        } else {
            AnyView(UnknownView(id: id, information: information))
        }
    }
}

private extension LockDetailView {
    
    var cache: LockCache? {
        store[lock: id]
    }
    
    var information: LockInformation? {
        store.lockInformation.first(where: { $0.value.id == id })?.value
    }
    
    var events: Int {
        let fetchRequest = EventManagedObject.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(EventManagedObject.lock.identifier),
            id as NSUUID
        )
        return (try? managedObjectContext.count(for: fetchRequest)) ?? 0
    }
    
    var keys: Int {
        let fetchRequest = KeyManagedObject.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(KeyManagedObject.lock.identifier),
            id as NSUUID
        )
        return (try? managedObjectContext.count(for: fetchRequest)) ?? 0
    }
    
    var newKeys: Int {
        let fetchRequest = NewKeyManagedObject.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(NewKeyManagedObject.lock.identifier),
            id as NSUUID
        )
        return (try? managedObjectContext.count(for: fetchRequest)) ?? 0
    }
    
    func newPermission() {
        showNewKeyModal = true
    }
    
    func didCreateNewKey(url: URL, invitation: NewKey.Invitation) {
        showNewKeyModal = false
        reload()
    }
    
    func reload() {
        let lock = self.id
        activityIndicator = true
        pendingTask?.cancel()
        pendingTask = Task {
            activityIndicator = true
            defer { Task { await MainActor.run { activityIndicator = false } } }
            guard await store.central.state == .poweredOn else {
                return
            }
            let context = store.backgroundContext
            store.stopScanning()
            // scan and find device
            do {
                if let peripheral = try await store.device(for: lock) {
                    try await store.central.connection(for: peripheral) { connection in
                        // read information
                        let _ = try await store.readInformation(for: connection)
                        // load latest events
                        var lastEventDate: Date?
                        try? await context.perform {
                            lastEventDate = try context.find(id: lock, type: LockManagedObject.self)
                                .flatMap { try $0.lastEvent(in: context)?.date }
                        }
                        let fetchRequest = LockEvent.FetchRequest(
                            offset: 0,
                            limit: nil,
                            predicate: LockEvent.Predicate(
                                keys: nil,
                                start: lastEventDate,
                                end: nil
                            )
                        )
                        let _ = try await store.listEvents(for: connection, fetchRequest: fetchRequest)
                        // load keys if admin
                        if let permssion = store[lock: lock]?.key.permission, permssion.isAdministrator {
                            try await store.listKeys(for: connection)
                        }
                    }
                }
            } catch {
                log("⚠️ Error loading information for \(lock). \(error)")
            }
        }
    }
    
    func unlock() {
        Task {
            guard await store.central.state == .poweredOn else {
                return
            }
            #if os(iOS) || os(macOS)
            // FaceID
            let authentication = LAContext()
            let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
            let reason = NSLocalizedString("Biometrics are needed to unlock", comment: "")
            do {
                if (try? authentication.canEvaluate(policy: policy)) ?? false {
                    try await authentication.evaluatePolicy(policy, localizedReason: reason)
                }
            }
            catch {
                log("⚠️ Unable to authenticate for unlock \(id). \(error)")
                self.error = error
                return
            }
            #endif
            // cancel all operation
            if store.isScanning {
                store.stopScanning()
            }
            pendingTask?.cancel()
            pendingTask = Task {
                do {
                    // Bluetooth request
                    try await store.unlock(for: id, action: .default)
                } catch {
                    log("⚠️ Unable to unlock \(id). \(error)")
                    self.error = error
                }
            }
        }
    }
}

extension LockDetailView {
    
    struct StateView: View {
        
        let id: UUID
        
        let cache: LockCache
        
        let events: Int
        
        let keys: Int
        
        let newKeys: Int
        
        @State
        var showID = false
        
        let unlock: () -> ()
        
        @State
        private var enableActions = true
        
        public var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing * 2) {
                    HStack {
                        Spacer()
                        // unlock button
                        Button(action: unlock, label: {
                            PermissionIconView(permission: cache.key.permission.type)
                                .frame(width: buttonSize, height: buttonSize, alignment: .center)
                        })
                        .buttonStyle(.plain)
                        #if !os(watchOS)
                        .padding(30)
                        #endif
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: spacing) {
                        #if os(tvOS)
                        Button(action: unlock, label: {
                            Text("Unlock")
                                .font(.headline)
                        })
                        #endif
                        // info
                        if showID {
                            DetailRowView(
                                title: "Lock",
                                value: id.description
                            )
                            DetailRowView(
                                title: "Key",
                                value: cache.key.id.description
                            )
                        }
                        DetailRowView(
                            title: "Type",
                            value: cache.key.permission.localizedText,
                            action: { showID.toggle() }
                        )
                        DetailRowView(
                            title: "Created",
                            value: Self.dateFormatter.string(from: cache.key.created)
                        )
                        DetailRowView(
                            title: "Version",
                            value: "v\(cache.information.version.description)"
                        )
                        DetailRowView(
                            title: "History",
                            value: "\(events) events",
                            link: .events(id, nil)
                        )
                        if cache.key.permission.isAdministrator {
                            DetailRowView(
                                title: "Permissions",
                                value: newKeys > 0 ? "\(keys) keys, \(newKeys) pending" : "\(keys) keys",
                                link: .permissions(id)
                            )
                        }
                    }
                }
                .padding(padding)
                .buttonStyle(.plain)
            }
            .navigationTitle(Text(verbatim: cache.name))
        }
    }
}

private extension LockDetailView.StateView {
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    private var buttonSize: CGFloat {
        #if os(watchOS)
        100
        #else
        150
        #endif
    }
    
    private var spacing: CGFloat {
        #if os(watchOS)
        8
        #else
        20
        #endif
    }
    
    var padding: CGFloat {
        #if os(watchOS)
        8
        #else
        20
        #endif
    }
}

extension LockDetailView {
    
    struct UnknownView: View {
        
        let id: UUID
        
        let information: LockInformation?
        
        var body: some View {
            VStack {
                Text("Lock")
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
                    events: 10,
                    keys: 2,
                    newKeys: 5,
                    unlock: { }
                )
            }
            
            NavigationView {
                LockDetailView.UnknownView(
                    id: UUID(),
                    information: LockInformation(id: UUID(), status: .unlock)
                )
            }
            .previewDisplayName("Unknown View")
        }
    }
}
