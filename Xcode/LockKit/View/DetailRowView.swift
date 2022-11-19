//
//  DetailRowView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/28/22.
//

import SwiftUI

public struct DetailRowView: View {
    
    internal let title: LocalizedStringKey
    
    internal let value: Value
    
    public init(title: LocalizedStringKey, value: String) {
        self.title = title
        self.value = .text(value)
    }
    
    public init(title: LocalizedStringKey, value: String, action: @escaping () -> ()) {
        self.title = title
        self.value = .button(value, action)
    }
    
    public init(title: LocalizedStringKey, value: String, link: AppNavigationLinkID) {
        self.title = title
        self.value = .link(value, link)
    }
    
    public var body: some View {
        stackView
    }
}

internal extension DetailRowView {
    
    enum Value {
        case text(String)
        case button(String, () -> ())
        case link(String, AppNavigationLinkID)
    }
}

private extension DetailRowView {
    
    #if !os(watchOS)
    var titleWidth: CGFloat {
        #if os(iOS)
        100
        #elseif os(macOS)
        100
        #elseif os(tvOS)
        300
        #endif
    }
    #endif
    
    var stackView: some View {
        #if os(watchOS) || os(tvOS)
        switch value {
        case let .text(value):
            return AnyView(VStack(alignment: .leading) {
                Text(verbatim: value)
                titleView
            })
        case let .button(value, action):
            return AnyView(Button(action: action, label: {
                VStack(alignment: .leading) {
                    Text(verbatim: value)
                    titleView
                }
            }))
        case let .link(value, link):
            return AnyView(AppNavigationLink(id: link, label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(verbatim: value)
                        titleView
                    }
                    Spacer(minLength: 3)
                    Image(systemSymbol: .chevronRight)
                }
            }))
        }
        #else
        HStack {
            switch value {
            case let .text(value):
                titleView
                Text(verbatim: value)
                    .foregroundColor(.primary)
            case let .button(value, action):
                titleView
                Button(action: action, label: {
                    Text(verbatim: value)
                        .foregroundColor(.primary)
                })
            case let .link(value, link):
                titleView
                AppNavigationLink(id: link, label: {
                    HStack {
                        Text(verbatim: value)
                            .foregroundColor(.primary)
                        Image(systemSymbol: .chevronRight)
                    }
                })
                .foregroundColor(.primary)
            }
        }
        #endif
    }
    
    var titleView: some View {
        #if os(watchOS)
        Text(title)
            .font(.body)
            .foregroundColor(.gray)
        #else
        Text(title)
            .frame(width: titleWidth, height: nil, alignment: .leading)
            .font(.body)
            .foregroundColor(.gray)
        #endif
    }
}

#if DEBUG
struct DetailRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 8) {
            DetailRowView(
                title: "Lock",
                value: "\(UUID())"
            )
            DetailRowView(
                title: "Key",
                value: "\(UUID())"
            )
            DetailRowView(
                title: "Type",
                value: "Admin"
            )
            Spacer(minLength: 20)
        }
    }
}
#endif
