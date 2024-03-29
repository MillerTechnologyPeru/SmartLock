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
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            navigationViewLink
        } else {
            navigationViewLink
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
    
    @available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
    var navigationStackLink: some View {
        NavigationLink(value: id, label: { label })
    }
}

// MARK: - Supporting Types

public enum AppNavigationLinkID: Hashable {
    
    case lock(UUID)
    case setup(UUID, KeyData)
    case events(UUID, LockEvent.Predicate?)
    case permissions(UUID)
    case key(UUID, KeyDetailView.Value)
    case newKeyInvitation(NewKey.Invitation)
    
    #if os(iOS) || os(macOS)
    case keySchedule(Permission.Schedule) // view only
    #endif
}

public enum AppNavigationLinkType: String {
    
    case lock
    case setup
    case events
    case permissions
    case key
    case newKeyInvitation
    
    #if os(iOS) || os(macOS)
    case keySchedule
    #endif
}

public extension AppNavigationLinkID {
    
    var type: AppNavigationLinkType {
        switch self {
        case .lock:
            return .lock
        case .setup:
            return .setup
        case .events:
            return .events
        case .permissions:
            return .permissions
        case .key:
            return .key
        #if os(iOS) || os(macOS)
        case .keySchedule:
            return .keySchedule
        #endif
        case .newKeyInvitation:
            return .newKeyInvitation
        }
    }
}

public struct AppNavigationDestinationView: View, Identifiable {
    
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
        case let .setup(id, sharedSecret):
            AnyView(
                SetupLockView(lock: id, sharedSecret: sharedSecret)
            )
        case let .events(lock, predicate):
            AnyView(
                EventsView(lock: lock, predicate: predicate)
            )
        case let .permissions(id):
            AnyView(
                PermissionsView(id: id)
            )
        case let .key(lock, key):
            AnyView(
                KeyDetailView(key: key, lock: lock)
            )
        #if os(iOS) || os(macOS)
        case let .keySchedule(schedule):
            AnyView(
                PermissionScheduleView(schedule: schedule)
            )
        #endif
        case let .newKeyInvitation(invitation):
            AnyView(
                NewKeyInvitationView(invitation: invitation)
            )
        }
    }
}
