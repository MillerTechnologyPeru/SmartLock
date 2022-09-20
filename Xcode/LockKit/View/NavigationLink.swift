//
//  NavigationLink.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/20/22.
//

import SwiftUI

#if os(macOS)

public var AppNavigationLinkNavigate: (AnyView) -> () = { _ in assertionFailure() }

public struct AppNavigationLink <Destination: View, Label: View> : View {
    
    private let destination: Destination
    
    private let label: Label
    
    public var body: some View {
        Button(
            action: buttonAction,
            label: { label }
        )
        .buttonStyle(.plain)
    }
    
    public init(destination: () -> Destination, label: () -> Label) {
        self.destination = destination()
        self.label = label()
    }
}

private extension AppNavigationLink {
    
    func buttonAction() {
        AppNavigationLinkNavigate(AnyView(destination))
    }
}

#else
public typealias AppNavigationLink = SwiftUI.NavigationLink
#endif
