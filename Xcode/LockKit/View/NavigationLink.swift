//
//  NavigationLink.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/20/22.
//

import SwiftUI

public var AppNavigationLinkNavigate: (String, AnyView) -> () = { _, _ in assertionFailure() }

public struct AppNavigationLink <Destination: View, Label: View, ID: Hashable> : View {
    
    public let id: ID
    
    private let destination: Destination
    
    private let label: Label
    
    public var body: some View {
        #if os(macOS)
        Button(
            action: buttonAction,
            label: { label }
        )
        .buttonStyle(.plain)
        #else
        NavigationLink(destination: destination, label: label)
        #endif
    }
    
    public init(id: ID, destination: () -> Destination, label: () -> Label) {
        self.id = id
        self.destination = destination()
        self.label = label()
    }
}

private extension AppNavigationLink {
    
    func buttonAction() {
        AppNavigationLinkNavigate("\(id)", AnyView(destination))
    }
}
