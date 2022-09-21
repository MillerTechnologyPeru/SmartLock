//
//  NavigationLink.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/20/22.
//

import SwiftUI

public struct AppNavigationLink <Destination: View, Label: View> : View {
    
    public typealias ID = AppNavigationLinkID
    
    public let id: ID
    
    private let destination: Destination
    
    private let label: Label
    
    #if os(macOS)
    @EnvironmentObject
    private var coordinator: AppNavigationLinkCoordinator
    #endif
    
    public var body: some View {
        #if os(macOS)
        Button(
            action: buttonAction,
            label: { label }
        )
        .buttonStyle(.plain)
        #else
        NavigationLink(destination: destination, label: { label })
        #endif
    }
    
    public init(id: ID, destination: () -> Destination, label: () -> Label) {
        self.id = id
        self.destination = destination()
        self.label = label()
    }
}

#if os(macOS)
private extension AppNavigationLink {
    
    func buttonAction() {
        coordinator.current = (id: id, view: AnyView(destination))
    }
}
#endif

// MARK: - Supporting Types

public enum AppNavigationLinkID: Hashable {
    
    case lock(UUID)
    case events(UUID)
    case permissions(UUID)
    case key(UUID, pending: Bool = false)
    case keySchedule(UUID)
    
    static func newKey(_ id: UUID) -> AppNavigationLinkID {
        .key(id, pending: true)
    }
}

public enum AppNavigationLinkType: String {
    
    case lock
    case events
    case permissions
    case key
    case keySchedule
}

public extension AppNavigationLinkID {
    
    var type: AppNavigationLinkType {
        switch self {
        case .lock:
            return .lock
        case .events:
            return .events
        case .permissions:
            return .permissions
        case .key:
            return .key
        case .keySchedule:
            return .keySchedule
        }
    }
}

#if os(macOS)
public final class AppNavigationLinkCoordinator: ObservableObject {
    
    @Published
    public var current: (id: AppNavigationLinkID, view: AnyView)?
    
    public init() { }
}
#endif
