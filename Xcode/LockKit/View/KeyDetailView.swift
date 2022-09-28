//
//  KeyDetailView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/20/22.
//

import SwiftUI
import CoreLock

public struct KeyDetailView: View {
    
    @EnvironmentObject
    public var store: Store
    
    public let key: Value
    
    public let lock: UUID
    
    public init(key: Value, lock: UUID) {
        self.key = key
        self.lock = lock
    }
    
    public var body: some View {
        StateView(
            key: key,
            lock: lockText,
            showID: false
        )
    }
}

private extension KeyDetailView {
    
    var lockText: String {
        return store.applicationData.locks[lock]?.name ?? lock.description
    }
}

extension KeyDetailView {
    
    struct StateView: View {
        
        let key: Value
        
        let lock: String
        
        @State
        var showID = false
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing * 2) {
                    HStack {
                        Spacer()
                        PermissionIconView(permission: key.permission.type)
                            .frame(width: buttonSize, height: buttonSize, alignment: .center)
                        #if !os(watchOS)
                        .padding(30)
                        #endif
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: spacing) {
                        // info
                        if showID {
                            DetailRowView(
                                title: "Key",
                                value: key.id.description
                            )
                        }
                        DetailRowView(
                            title: "Lock",
                            value: lock
                        )
                        #if os(iOS) || os(macOS)
                        if let schedule = key.permission.schedule {
                            DetailRowView(
                                title: "Type",
                                value: key.permission.localizedText,
                                link: .keySchedule(schedule)
                            )
                        } else {
                            DetailRowView(
                                title: "Type",
                                value: key.permission.localizedText
                            )
                        }
                        #else
                        DetailRowView(
                            title: "Type",
                            value: key.permission.localizedText
                        )
                        #endif
                        DetailRowView(
                            title: "Created",
                            value: Self.dateFormatter.string(from: key.created)
                        )
                        if let expiration = key.expiration {
                            DetailRowView(
                                title: "Expiration",
                                value: Self.dateFormatter.string(from: expiration)
                            )
                        }
                    }
                }
                .padding(padding)
                .buttonStyle(.plain)
            }
            .navigationTitle(Text(verbatim: key.name))
        }
    }
}

private extension KeyDetailView.StateView {
    
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

// MARK: - Supporting Types

public extension KeyDetailView {
    
    enum Value: Equatable, Hashable {
        case key(Key)
        case newKey(NewKey)
    }
}

extension KeyDetailView.Value: Identifiable {
    
    public var id: UUID {
        switch self {
        case .key(let key):
            return key.id
        case .newKey(let newKey):
            return newKey.id
        }
    }
}

public extension KeyDetailView.Value {
    
    var name: String {
        switch self {
        case .key(let key):
            return key.name
        case .newKey(let newKey):
            return newKey.name
        }
    }
    
    var created: Date {
        switch self {
        case .key(let key):
            return key.created
        case .newKey(let newKey):
            return newKey.created
        }
    }
    
    var permission: Permission {
        switch self {
        case .key(let key):
            return key.permission
        case .newKey(let newKey):
            return newKey.permission
        }
    }
    
    var expiration: Date? {
        switch self {
        case .key:
            return nil
        case .newKey(let newKey):
            return newKey.expiration
        }
    }
}

// MARK: - Preview

#if DEBUG
struct KeyDetailView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            ForEach(keys) { key in
                NavigationView {
                    KeyDetailView(
                        key: key,
                        lock: UUID()
                    )
                }
                .previewDisplayName(key.name)
            }
        }
    }
    
    static let keys: [KeyDetailView.Value] = [
        .key(
            Key(
                id: UUID(),
                name: "Owner",
                created: Date() - 60 * 60 * 24,
                permission: .owner
            )
        ),
        .key(
            Key(
                id: UUID(),
                name: "Key 2",
                created: Date() - 60 * 60 * 24,
                permission: .admin
            )
        ),
        .key(
            Key(
                id: UUID(),
                name: "Key 3",
                created: Date() - 60 * 60 * 24,
                permission: .anytime
            )
        ),
        .newKey(
                NewKey(
                    id: UUID(),
                    name: "New Key",
                    permission: .scheduled(
                        Permission.Schedule(
                            expiry: Date() + 60 * 60 * 24 * 90,
                            interval: .default,
                            weekdays: .workdays
                        )
                    ),
                    created: Date() - 60 * 60 * 2,
                    expiration: Date() + 60 * 60 * 25
                )
        )
    ]
}
#endif
