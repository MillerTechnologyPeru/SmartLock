//
//  LockDetailView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/19/22.
//

import SwiftUI
import CoreLock
import LocalAuthentication

public struct LockDetailView: View {
        
    @EnvironmentObject
    public var store: Store
    
    @Environment(\.managedObjectContext)
    public var managedObjectContext
    
    public let id: UUID
    
    @State
    private var activityIndicator = false
    
    @State
    private var pendingTask: TaskQueue.PendingTask?
    
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
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { }) {
                            Image(systemSymbol: .pencil)
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { }) {
                            Image(systemSymbol: .trash)
                        }
                    }
                    
                    // create new key
                    ToolbarItem(placement: .primaryAction) {
                        if cache.key.permission.isAdministrator {
                            Button(action: newPermission) {
                                Image(systemSymbol: .plus)
                            }
                        }
                    }
                }
            )
        } else if let information = self.information,
            information.status == .setup {
            #if os(iOS)
            AnyView(SetupLockView(id: id))
            #else
            AnyView(Text("Scan to Setup"))
            #endif
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
    
    func didCreateNewKey(_ newKey: NewKey.Invitation) {
        
    }
    
    func reload() {
        let lock = self.id
        activityIndicator = true
        Task {
            await pendingTask?.cancel()
            await pendingTask = Task.bluetooth {
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
    }
    
    func unlock() {
        // FIXME: Handle errors
        Task {
            guard await store.central.state == .poweredOn else {
                return
            }
            // FaceID
            let authentication = LAContext()
            let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
            let reason = NSLocalizedString("Biometrics are needed to unlock", comment: "")
            do {
                if try authentication.canEvaluate(policy: policy) {
                    try await authentication.evaluatePolicy(policy, localizedReason: reason)
                }
            }
            catch {
                log("⚠️ Unable to authenticate for unlock \(id). \(error)")
                self.error = error
                return
            }
            // cancel all operation
            if store.isScanning {
                store.stopScanning()
            }
            await TaskQueue.bluetooth.cancelAll()
            await pendingTask?.cancel()
            pendingTask = await Task.bluetooth {
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
        
        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }()
        
        private var titleWidth: CGFloat {
            100
        }
        
        public var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer()
                        // unlock button
                        Button(action: unlock, label: {
                            PermissionIconView(permission: cache.key.permission.type)
                                .frame(width: 150, height: 150, alignment: .center)
                        })
                        .buttonStyle(.plain)
                        //.disabled(enableActions == false)
                        .padding(30)
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 20) {
                        // info
                        if showID {
                            HStack {
                                Text("Lock")
                                    .frame(width: titleWidth, height: nil, alignment: .leading)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                Text(verbatim: id.description)
                            }
                            HStack {
                                Text("Key")
                                    .frame(width: titleWidth, height: nil, alignment: .leading)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                Text(verbatim: cache.key.id.description)
                            }
                        }
                        HStack {
                            Text("Type")
                                .frame(width: titleWidth, height: nil, alignment: .leading)
                                .font(.body)
                                .foregroundColor(.gray)
                            Button(action: {
                                showID.toggle()
                            }, label: {
                                Text(verbatim: cache.key.permission.localizedText)
                                    .foregroundColor(.primary)
                            })
                        }
                        HStack {
                            Text("Created")
                                .frame(width: titleWidth, height: nil, alignment: .leading)
                                .font(.body)
                                .foregroundColor(.gray)
                            Text(verbatim: Self.dateFormatter.string(from: cache.key.created))
                        }
                        HStack {
                            Text("Version")
                                .frame(width: titleWidth, height: nil, alignment: .leading)
                                .font(.body)
                                .foregroundColor(.gray)
                            Text(verbatim: "v\(cache.information.version.description)")
                        }
                        HStack {
                            Text("History")
                                .frame(width: titleWidth, height: nil, alignment: .leading)
                                .font(.body)
                                .foregroundColor(.gray)
                            AppNavigationLink(id: .events(.init(keys: [cache.key.id])), label: {
                                HStack {
                                    Text("\(events) events")
                                    Image(systemName: "chevron.right")
                                }
                            })
                            .foregroundColor(.primary)
                        }
                        if cache.key.permission.isAdministrator {
                            HStack {
                                Text("Permissions")
                                    .frame(width: titleWidth, height: nil, alignment: .leading)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                AppNavigationLink(id: .permissions(id), label: {
                                    HStack {
                                        if newKeys > 0 {
                                            Text("\(keys) keys, \(newKeys) pending")
                                        } else {
                                            Text("\(keys) keys")
                                        }
                                        Image(systemName: "chevron.right")
                                    }
                                })
                                .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding(20)
                .buttonStyle(.plain)
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
