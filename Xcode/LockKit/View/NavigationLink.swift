//
//  NavigationLink.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/20/22.
//

import SwiftUI
import CoreLock

public struct AppNavigationLink <Label: View> : View {
    
    public typealias ID = AppNavigationLinkID
    
    public let id: ID
    
    private let label: Label
    
    public var body: some View {
        #if os(macOS)
        if #available(macOS 13, iOS 16, tvOS 16, *) {
            navigationStackLink
        } else {
            
        }
        #else
        navigationViewLink
        #endif
    }
    
    public init(id: ID, label: () -> Label) {
        self.id = id
        self.label = label()
    }
}

private extension AppNavigationLink {
    
    var navigationViewLink: some View {
        NavigationLink(destination: {
            AppNavigationDestinationView(id: id)
        }, label: {
            label
        })
    }
    
    @available(macOS 13, iOS 16, tvOS 16, *)
    var navigationStackLink: some View {
        NavigationLink(value: id, label: { label })
    }
}

// MARK: - Supporting Types

public enum AppNavigationLinkID: Hashable {
    
    case lock(UUID)
    case events(UUID, LockEvent.Predicate?)
    case permissions(UUID)
    case key(KeyDetailView.Value)
    case keySchedule(Permission.Schedule) // view only
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

public struct AppNavigationDestinationView: View {
    
    public let id: AppNavigationLinkID
    
    public init(id: AppNavigationLinkID) {
        self.id = id
    }
    
    public var body: some View {
        switch id {
        case let .lock(id):
            AnyView(
                LockDetailView(id: id)
            )
        case let .events(lock, predicate):
            AnyView(
                EventsView(lock: lock, predicate: predicate)
            )
        case let .permissions(id):
            AnyView(
                PermissionsView(id: id)
            )
        case let .key(key):
            AnyView(
                KeyDetailView(key: key)
            )
        case let .keySchedule(schedule):
            AnyView(
                PermissionScheduleView(schedule: schedule)
            )
        }
    }
}
