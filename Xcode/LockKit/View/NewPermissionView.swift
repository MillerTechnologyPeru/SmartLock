//
//  NewPermissionView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/20/22.
//

import SwiftUI
import CoreLock

public struct NewPermissionView: View {
    
    @EnvironmentObject
    public var store: Store
    
    @Environment(\.managedObjectContext)
    public var managedObjectContext
    
    public let id: UUID
    
    private var completion: (NewKey.Invitation) -> () = { _ in }
    
    @State
    private var permission: Permission = .anytime
    
    @State
    private var name: String = ""
    
    @State
    private var state: ViewState = .editing
    
    public init(
        id: UUID,
        name: String = "",
        permission: Permission = .anytime,
        completion: @escaping (NewKey.Invitation) -> ()
    ) {
        self.id = id
        self.name = name
        self.permission = permission
        self.completion = completion
    }
    
    public var body: some View {
        StateView(
            permission: $permission,
            name: $name,
            state: $state,
            create: create
        )
    }
}

private extension NewPermissionView {
    
    func create() {
        state = .loading
        let permission = self.permission
        let name = self.name.isEmpty ? "\(permission.type.localizedText) Key" : self.name
        #if targetEnvironment(simulator)
        Task {
            try? await Task.sleep(timeInterval: 1)
            if self.name.isEmpty {
                state = .error("Unable to connect to device.")
            }
        }
        #else
        Task {
            await Task.bluetooth {
                do {
                    guard await store.central.state == .poweredOn else {
                        throw LockError.bluetoothUnavailable
                    }
                    if store.isScanning {
                        store.stopScanning()
                    }
                    guard let peripheral = try await store.device(for: id) else {
                        throw LockError.notInRange(lock: id)
                    }
                    let newKey = try await store.newKey(
                        for: peripheral,
                        permission: permission,
                        name: name
                    )
                    state = .editing
                    completion(newKey)
                } catch {
                    state = .error(error.localizedDescription)
                    log("⚠️ Error creating new key for \(id). \(error)")
                }
            }
        }
        #endif
    }
}

internal extension NewPermissionView {
    
    enum ViewState: Equatable, Hashable {
        case editing
        case loading
        case error(String)
    }
}

internal extension NewPermissionView {
    
    struct StateView: View {
        
        @Binding
        var permission: Permission
        
        @Binding
        var name: String
        
        @Binding
        var state: ViewState
        
        let create: () -> ()
        
        var body: some View {
            form
            .disabled(state == .loading)
            .navigationTitle("New Key")
            .toolbar {
                createToolbarItem
            }
        }
    }
}

private extension NewPermissionView.StateView {
    
    var permissionTypes: [PermissionType] {
        [.admin, .anytime, .scheduled]
    }
    
    var form: some View {
        Form {
            if case let .error(error) = state {
                Section("") {
                    Text(verbatim: "⚠️ " + error)
                }
            }
            nameSection
            permissionSection
            #if os(macOS)
            Spacer(minLength: 20)
            PermissionScheduleView(
                schedule: schedule
            )
            #endif
        }
    }
    
    var createToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if state == .loading {
                AnyView(
                    ProgressView()
                        .progressViewStyle(.circular)
                )
            } else {
                AnyView(
                    Button("Create", action: { create() })
                )
            }
        }
    }
    
    var nameSection: some View {
        Section(header: Text("Name")) {
            TextField("New Key", text: $name)
        }
    }
    
    var permissionSection: some View {
        Section(header: Text("Permission")) {
            ForEach(permissionTypes, id: \.rawValue) { type in
                if type == .scheduled {
                    #if os(macOS)
                    Button(action: {
                        permission = .scheduled(.init(interval: .default))
                    }, label: {
                        NewPermissionView.PermissionTypeView(
                            permission: type,
                            isSelected: self.permission.type == type
                        )
                    })
                    .buttonStyle(.plain)
                    #else
                    NavigationLink(destination: {
                        PermissionScheduleView(
                            schedule: schedule
                        )
                    }, label: {
                        NewPermissionView.PermissionTypeView(
                            permission: type,
                            isSelected: self.permission.type == type
                        )
                    })
                    #endif
                } else {
                    Button(action: {
                        switch type {
                        case .admin:
                            permission = .admin
                        case .anytime:
                            permission = .anytime
                        default:
                            assertionFailure()
                        }
                    }, label: {
                        NewPermissionView.PermissionTypeView(
                            permission: type,
                            isSelected: self.permission.type == type
                        )
                    })
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    var schedule: Binding<Permission.Schedule> {
        Binding(get: {
            // default schedule is the same as anytime
            return permission.schedule ?? Permission.Schedule()
        }, set: {
            // schedule must be customized
            if $0 == .init() {
                permission = .anytime
            } else {
                permission = .scheduled($0)
            }
        })
    }
}

internal extension NewPermissionView {
    
    struct PermissionTypeView: View {
        
        let permission: PermissionType
        
        let isSelected: Bool
        
        var body: some View {
            HStack(alignment: .center, spacing: 8) {
                LockRowView(
                    image: .permission(permission),
                    title: permission.localizedText,
                    subtitle: descriptionText
                )
                if isSelected {
                    Image(systemSymbol: .checkmark)
                        .frame(width: selectionInset)
                } else {
                    Spacer(minLength: selectionInset)
                }
            }
        }
    }
}

private extension NewPermissionView.PermissionTypeView {
    
    var selectionInset: CGFloat {
        25
    }
    
    var descriptionText: String {
        switch permission {
        case .admin:
            return "Admin keys have unlimited access, and can create new keys."
        case .anytime:
            return "Anytime keys have unlimited access, but cannot create new keys."
        case .scheduled:
            return "Scheduled keys have limited access during specified hours, and expire at a certain date. New keys cannot be created from this key."
        case .owner:
            assertionFailure("Cannot create owner keys")
            return "Cannot create owner keys"
        }
    }
}

#if DEBUG
struct NewPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NewPermissionView(id: UUID()) { _ in
                
            }
        }
    }
}
#endif
