//
//  EventsView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/19/22.
//

import SwiftUI
import CoreLock

public struct EventsView: View {
    
    @Environment(\.managedObjectContext)
    var managedObjectContext
    
    let lock: UUID?
    
    @FetchRequest(
        entity: EventManagedObject.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \EventManagedObject.date, ascending: false)
        ],
        predicate: nil
    )
    var events: FetchedResults<EventManagedObject>
    
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
    }
    
    func reload() {
        
    }
    
    func row(for managedObject: EventManagedObject) -> some View {
        //guard let lock = managedObject.lock?.identifier else {
        //    fatalError("Missing identifier")
        //}
        let context = self.managedObjectContext
        let eventType = type(of: managedObject).eventType
        let action: String
        var keyName: String
        let key = try! managedObject.key(in: context)
        if key == nil {
            //needsKeys.insert(lock)
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
                //needsKeys.insert(lock)
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
                    //needsKeys.insert(lock)
                }
            } else {
                action = "Created key" //R.string.locksEventsViewController.eventsCreatedNamed()
                keyName = ""
                //needsKeys.insert(lock)
            }
        case let event as RemoveKeyEventManagedObject:
            if let removedKey = try! event.removedKey(in: context)?.name {
                action = "Removed key \(removedKey)" //R.string.locksEventsViewController.eventsRemovedNamed(removedKey)
            } else {
                action = "Removed key" //R.string.locksEventsViewController.eventsRemoved()
                //needsKeys.insert(lock)
            }
            keyName = key?.name ?? ""
        default:
            fatalError("Invalid event \(managedObject)")
        }
        
        //let lockName = managedObject.lock?.name ?? ""
        //if self.lock == nil, lockName.isEmpty == false {
        //    keyName = keyName.isEmpty ? lockName : lockName + " - " + keyName
        //}
        
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
