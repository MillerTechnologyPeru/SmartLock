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
    
    public var body: some View {
        StateView(
            keys: keys.lazy.map { Key(managedObject: $0)! },
            newKeys: newKeys.lazy.map { NewKey(managedObject: $0)! },
            reload: reload
        )
        .onAppear {
            self.keys.nsPredicate = predicate
            self.newKeys.nsPredicate = predicate
        }
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
    
    func reload() {
        
    }
}

internal extension PermissionsView {
    
    struct StateView <Keys, NewKeys> : View where Keys: RandomAccessCollection, Keys.Element == Key, NewKeys: RandomAccessCollection, NewKeys.Element == NewKey {
        
        let keys: Keys
        
        let newKeys: NewKeys
        
        let reload: () -> ()
        
        var body: some View {
            List {
                ForEach(keys) {
                    row(for: $0)
                }
                .onDelete(perform: deleteKey)
                if newKeys.isEmpty == false {
                    Section("Pending") {
                        ForEach(newKeys) {
                            row(for: $0)
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
        AppNavigationLink(id: .key(item.id, pending: false), destination: {
            destination(for: item)
        }, label: {
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
    }
    
    func row(for item: NewKey) -> some View {
        AppNavigationLink(id: .newKey(item.id), destination: {
            destination(for: item)
        }, label: {
            LockRowView(
                image: .permission(item.permission.type),
                title: item.name,
                subtitle: item.permission.localizedText + "\n" + "Expires " + PermissionsView.relativeDateTimeFormatter.localizedString(for: item.expiration, relativeTo: Date()),
                trailing: (
                    PermissionsView.dateFormatter.string(from: item.created),
                    PermissionsView.timeFormatter.string(from: item.created)
                )
            )
        })
    }
    
    func destination(for item: Key) -> some View {
        Text("Key \(item.id)")
    }
    
    func destination(for item: NewKey) -> some View {
        Text("New Key \(item.id)")
    }
    
    func deleteKey(at indexSet: IndexSet) {
        
    }
    
    func deleteNewKey(at indexSet: IndexSet) {
        
    }
}

// MARK: - Preview

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PermissionsView.StateView(
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
                        id: UUID(),
                        name: "Key 4",
                        permission: .anytime,
                        created: Date() - 60 * 60 * 2,
                        expiration: Date() + (60 * 60 * 24 * 1) + 10
                    )
                ],
                reload: { }
            )
        }
    }
}
