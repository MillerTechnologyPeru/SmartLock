//
//  LockDetailView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/19/22.
//

import SwiftUI
import CoreLock

public struct LockDetailView: View {
        
    @EnvironmentObject
    public var store: Store
    
    public let id: UUID
    
    public var body: some View {
        if let cache = self.cache {
            AnyView(
                StateView(
                    id: id,
                    cache: cache,
                    events: events,
                    keys: keys,
                    unlock: unlock
                )
            )
        } else {
            AnyView(UnknownView(id: id, information: information))
        }
    }
    
    public init(id: UUID) {
        self.id = id
    }
}

private extension LockDetailView {
    
    var cache: LockCache? {
        store[lock: id]
    }
    
    var information: LockInformation? {
        store.lockInformation.first(where: { $0.value.id == id })?.value
    }
    
    func unlock() {
        Task {
            //store.unlock(for:action:)
        }
    }
    
    var events: Int {
        2
    }
    
    var keys: Int {
        1
    }
}

extension LockDetailView {
    
    struct StateView: View {
        
        let id: UUID
        
        let cache: LockCache
        
        let events: Int
        
        let keys: Int
        
        let unlock: () -> ()
        
        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }()
        
        
        private var titleWidth: CGFloat {
            110
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
                        .padding(30)
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 20) {
                        // info
                        if cache.key.permission.isAdministrator {
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
                            Text(verbatim: cache.key.permission.localizedText)
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
                            NavigationLink(destination: {
                                
                            }, label: {
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
                                    .frame(width: 100, height: nil, alignment: .leading)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                NavigationLink(destination: {
                                    
                                }, label: {
                                    HStack {
                                        Text("\(keys) keys")
                                        Image(systemName: "chevron.right")
                                    }
                                })
                                .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding(20)
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
                    unlock: { }
                )
            }
            
            NavigationView {
                LockDetailView.UnknownView(id: UUID(), information: nil)
            }
            .previewDisplayName("Unknown View")
        }
    }
}
