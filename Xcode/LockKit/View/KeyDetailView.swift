//
//  KeyDetailView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/20/22.
//

import SwiftUI
import CoreLock

public struct KeyDetailView: View {
    
    public let key: Value
    
    @State
    var showID = false
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    private var titleWidth: CGFloat {
        100
    }
    
    public init(key: Value) {
        self.key = key
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    PermissionIconView(permission: key.permission.type)
                        .frame(width: 150, height: 150, alignment: .center)
                    .padding(30)
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 20) {
                    // info
                    if showID {
                        HStack {
                            Text("Key")
                                .frame(width: titleWidth, height: nil, alignment: .leading)
                                .font(.body)
                                .foregroundColor(.gray)
                            Text(verbatim: key.id.description)
                        }
                    }
                    HStack {
                        Text("Type")
                            .frame(width: titleWidth, height: nil, alignment: .leading)
                            .font(.body)
                            .foregroundColor(.gray)
                        if let schedule = key.permission.schedule {
                            AppNavigationLink(id: .keySchedule(schedule), label: {
                                HStack {
                                    Text(verbatim: key.permission.localizedText)
                                        .foregroundColor(.primary)
                                    Image(systemName: "chevron.right")
                                }
                            })
                        } else {
                            Text(verbatim: key.permission.localizedText)
                                .foregroundColor(.primary)
                        }
                    }
                    HStack {
                        Text("Created")
                            .frame(width: titleWidth, height: nil, alignment: .leading)
                            .font(.body)
                            .foregroundColor(.gray)
                        Text(verbatim: Self.dateFormatter.string(from: key.created))
                    }
                    if let expiration = key.expiration {
                        HStack {
                            Text("Expiration")
                                .frame(width: titleWidth, height: nil, alignment: .leading)
                                .font(.body)
                                .foregroundColor(.gray)
                            Text(verbatim: Self.dateFormatter.string(from: expiration))
                        }
                    }
                }
            }
            .padding(20)
            .buttonStyle(.plain)
        }
        .navigationTitle(Text(verbatim: key.name))
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
                        key: key
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
