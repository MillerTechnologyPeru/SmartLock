//
//  EventsView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/19/22.
//

import Foundation
import CoreData
import SwiftUI
import CoreLock

public struct EventsView: View {
    
    @EnvironmentObject
    public var store: Store
    
    @Environment(\.managedObjectContext)
    public var managedObjectContext
    
    @State
    public var lock: UUID?
    
    @State
    public var predicate: LockEvent.Predicate?
    
    @FetchRequest(
        entity: EventManagedObject.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \EventManagedObject.date, ascending: false)
        ],
        predicate: nil,
        animation: .linear
    )
    private var events: FetchedResults<EventManagedObject>
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()
    
    private static let timeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    @State
    private var activityIndicator = false
    
    @State
    private var reloadTask: Task<Void, Never>?
        
    public init(lock: UUID? = nil, predicate: LockEvent.Predicate? = nil) {
        self.predicate = predicate
        self.lock = lock
    }
    
    public var body: some View {
        list
            .navigationTitle("History")
            .onAppear {
                self._events.wrappedValue.nsPredicate = self.predicate?.toFoundation(lock: lock)
            }
            .onDisappear {
                reloadTask?.cancel()
            }
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if activityIndicator {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
            #endif
            
    }
}

private extension EventsView {
    
    /// Locks to scan for.
    var locks: Set<UUID> {
        guard let keys = predicate?.keys, keys.isEmpty == false else {
            return Set(store.applicationData.locks.keys) // all locks
        }
        return Set(
            store.applicationData.locks
                .filter { keys.contains($0.key)  }
                .map { $0.key }
        )
    }
    
    var list: some View {
        List(events) {
            row(for: $0)
        }
        .refreshable {
            reload()
        }
        .onAppear {
            reload()
        }
        #if os(iOS)
        .listStyle(.plain)
        #endif
    }
    
    func reload() {
        let locks = locks.sorted(by: { $0.description < $1.description })
        activityIndicator = true
        reloadTask?.cancel()
        self.reloadTask = Task {
            defer { Task { await MainActor.run { activityIndicator = false } } }
            guard await store.central.state == .poweredOn else {
                return
            }
            let context = store.backgroundContext
            if store.isScanning {
                store.stopScanning()
            }
            for lock in locks {
                // load via Bonjour
                /*
                do {
                    
                } catch {
                    log("⚠️ Error loading events for \(lock) via Bonjour")
                }*/
                // scan and find device
                do {
                    if let peripheral = try await store.device(for: lock) {
                        try await store.central.connection(for: peripheral) { connection in
                            // load keys if admin
                            if let permssion = store[lock: lock]?.key.permission, permssion.isAdministrator {
                                try await store.listKeys(for: connection)
                            }
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
                            try await store.listEvents(for: connection, fetchRequest: fetchRequest)
                        }
                    }
                } catch {
                    log("⚠️ Error loading events for \(lock). \(error)")
                }
            }
        }
    }
    
    func row(for managedObject: EventManagedObject) -> some View {
        let eventType = type(of: managedObject).eventType
        let displayLockName = (self.predicate?.keys?.count ?? 0) == 1
        let (action, keyName, _) = try! managedObject.displayRepresentation(
            displayLockName: displayLockName,
            in: managedObjectContext
        )
        #if os(watchOS)
        return LockRowView(
            image: .emoji(eventType.symbol),
            title: action,
            subtitle: keyName + "\n" + (managedObject.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
        )
        #else
        return LockRowView(
            image: .emoji(eventType.symbol),
            title: action,
            subtitle: keyName,
            trailing: (
                managedObject.date.flatMap { Self.dateFormatter.string(from: $0) } ?? "",
                managedObject.date.flatMap { Self.timeFormatter.string(from: $0) } ?? ""
            )
        )
        #endif
    }
}

// MARK: - Preview

#if DEBUG
struct EventsView_Previews: PreviewProvider {
    
    static var previews: some View {
        PreviewView()
            .environmentObject(Store.shared)
            .environment(\.managedObjectContext, Store.shared.managedObjectContext)
    }
    
    struct PreviewView: View {
        
        @EnvironmentObject
        var store: Store
        
        @Environment(\.managedObjectContext)
        var managedObjectContext
        
        @State
        private var filter = false
        
        private var predicate: LockEvent.Predicate? {
            if filter {
                return LockEvent.Predicate(keys: [ownerKey])
            } else {
                return nil
            }
        }
        
        var body: some View {
            NavigationView {
                EventsView(lock: nil, predicate: predicate)
            }
        }
    }
}

private extension EventsView_Previews.PreviewView {
    
    var lock: UUID { UUID(uuidString: "9C4CF5A6-A3A9-4C82-A5AF-62DDC9C1E5AE")! }
    var ownerKey: UUID { UUID(uuidString: "43DF5757-93E3-436F-8D53-B6944FB5FF4C")! }
    var setupEvent: UUID { UUID(uuidString: "3A2762BE-0189-402B-A72A-E8AED8B35962")! }
    
    func insertLockData() {
        store.backgroundContext.commit {
            // insert owner key
            let key = Key(
                id: ownerKey,
                name: "Owner",
                created: Date() - 6,
                permission: .owner
            )
            // insert lock
            try $0.insert([
                lock: LockCache(
                    key: key,
                    name: "My lock",
                    information: .init(
                        buildVersion: .current,
                        version: .current,
                        status: .unlock,
                        unlockActions: [.default]
                    )
                )
            ])
            // insert setup event
            (try $0.insert(
                .setup(
                    LockEvent.Setup(
                        id: setupEvent,
                        date: key.created,
                        key: ownerKey
                    )
                ), for: lock
            ) as! SetupEventManagedObject)
                .date = key.created
        }
    }
    
    func insertNewEvents() {
        insertLockData()
        store.backgroundContext.commit {
            // insert new events
            let newKeyInvitation = UUID()
            let key = Key(
                id: UUID(),
                name: "Key 2",
                created: Date() - 4,
                permission: .anytime
            )
            try $0.insert(key, for: lock)
            try $0.insert(
                .unlock(
                    .init(
                        date: Date() - 5,
                        key: ownerKey,
                        action: .default
                    )
                ), for: lock
            )
            
            try $0.insert(
                .createNewKey(
                    .init(
                        date: Date() - 4,
                        key: ownerKey,
                        newKey: newKeyInvitation
                    )
                ), for: lock
            )
            try $0.insert(
                .confirmNewKey(
                    .init(
                        date: Date() - 3,
                        newKey: newKeyInvitation,
                        key: key.id
                    )
                ), for: lock
            )
            try $0.insert(
                .removeKey(
                    .init(
                        date: Date() - 2,
                        key: ownerKey,
                        removedKey: UUID(),
                        type: .key
                    )
                ), for: lock
            )
            try $0.insert(
                .unlock(
                    .init(
                        date: Date() - 1,
                        key: key.id,
                        action: .default
                    )
                ), for: lock
            )
        }
    }
}
#endif
