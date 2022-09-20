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
    
    public let lock: UUID?
    
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
    private var needsKeys = Set<UUID>()
    
    public var body: some View {
        list
            .navigationTitle("History")
            .onAppear {
                self._events.wrappedValue.nsPredicate = self.predicate
            }
    }
    
    public init(lock: UUID? = nil) {
        self.lock = lock
    }
}

private extension EventsView {
    
    var predicate: NSPredicate? {
        lock.flatMap {
            NSPredicate(
                format: "%K == %@",
                #keyPath(EventManagedObject.lock.identifier),
                $0 as NSUUID
            )
        }
    }
    
    var locks: Set<UUID> {
        return self.lock.flatMap { [$0] } ?? Set(store.applicationData.locks.keys)
    }
    
    var list: some View {
        List(events) {
            row(for: $0)
        }
        .listStyle(.plain)
        .refreshable {
            reload()
        }
        .onAppear {
            reload()
        }
    }
    
    func reload() {
        let locks = locks.sorted(by: { $0.description < $1.description })
        Task {
            let context = store.backgroundContext
            store.stopScanning()
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
                        // load keys if admin
                        if let permssion = store[lock: lock]?.key.permission, permssion.isAdministrator {
                            try await store.listKeys(for: peripheral)
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
                        try await store.listEvents(for: peripheral, fetchRequest: fetchRequest)
                    }
                } catch {
                    log("⚠️ Error loading events for \(lock)")
                }
            }
        }
    }
    
    func row(for managedObject: EventManagedObject) -> some View {
        var needsKeys = Set<UUID>()
        guard let lock = managedObject.lock?.identifier else {
            fatalError("Missing identifier")
        }
        let context = self.managedObjectContext
        let eventType = type(of: managedObject).eventType
        let action: String
        var keyName: String
        let key = try! managedObject.key(in: context)
        if key == nil {
            needsKeys.insert(lock)
        }
        switch managedObject {
        case is SetupEventManagedObject:
            action = "Setup" //R.string.locksEventsViewController.eventsSetup()
            keyName = key?.name ?? ""
        case is UnlockEventManagedObject:
            action = "Unlocked" //R.string.locksEventsViewController.eventsUnlocked()
            keyName = key?.name ?? ""
        case let event as CreateNewKeyEventManagedObject:
            if let newKey = try! event.confirmKeyEvent(in: context)?.key(in: context)?.name {
                action = "Shared \(newKey)" //R.string.locksEventsViewController.eventsSharedNamed(newKey)
            } else if let newKey = try! event.newKey(in: context)?.name {
                action = "Shared \(newKey)" //R.string.locksEventsViewController.eventsSharedNamed(newKey)
            } else {
                action = "Shared key" //R.string.locksEventsViewController.eventsShared()
                needsKeys.insert(lock)
            }
            keyName = key?.name ?? ""
        case let event as ConfirmNewKeyEventManagedObject:
            if let key = key,
                let permission = PermissionType(rawValue: numericCast(key.permission)) {
                action = "Recieved \(permission.localizedText) from \(key.name ?? "")" //R.string.locksEventsViewController.eventsCreated(key.name ?? "", permission.localizedText)
                if let parentKey = try! event.createKeyEvent(in: context)?.key(in: context) {
                    keyName = "Shared by \(parentKey.name ?? "")" //R.string.locksEventsViewController.eventsSharedBy(parentKey.name ?? "")
                } else {
                    keyName = ""
                    needsKeys.insert(lock)
                }
            } else {
                action = "Created key" //R.string.locksEventsViewController.eventsCreatedNamed()
                keyName = ""
                needsKeys.insert(lock)
            }
        case let event as RemoveKeyEventManagedObject:
            if let removedKey = try! event.removedKey(in: context)?.name {
                action = "Removed key \(removedKey)" //R.string.locksEventsViewController.eventsRemovedNamed(removedKey)
            } else {
                action = "Removed key" //R.string.locksEventsViewController.eventsRemoved()
                needsKeys.insert(lock)
            }
            keyName = key?.name ?? ""
        default:
            fatalError("Invalid event \(managedObject)")
        }
        
        let lockName = managedObject.lock?.name ?? ""
        if self.lock == nil, lockName.isEmpty == false {
            keyName = keyName.isEmpty ? lockName : lockName + " - " + keyName
        }
        
        return LockRowView(
            image: .emoji(eventType.symbol),
            title: action,
            subtitle: keyName,
            trailing: (
                managedObject.date.flatMap { Self.dateFormatter.string(from: $0) } ?? "",
                managedObject.date.flatMap { Self.timeFormatter.string(from: $0) } ?? ""
            )
        )
    }
}

// MARK: - Preview

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
        
        var body: some View {
            NavigationView {
                EventsView(lock: filter ? lock : nil)
                    .onAppear(perform: insertLockData)
                    .navigationBarItems(
                        leading: Button(
                            filter ? "Show All" : "Filter",
                            action: { filter.toggle() }
                        ),
                        trailing: Button(
                            "Insert",
                            action: insertNewEvents
                        )
                    )
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
