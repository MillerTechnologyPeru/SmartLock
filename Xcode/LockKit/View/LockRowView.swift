//
//  LockCellView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import SwiftUI
import CoreLock

public struct LockRowView: View {
    
    public let image: Image
    
    public let title: String
    
    public let subtitle: String?
    
    public let trailing: (String, String)?
    
    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack {
                ImageView(image: image)
                    .frame(width: 50, height: 50, alignment: .center)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: title)
                    .font(.system(size: 19))
                if let subtitle = subtitle {
                    Text(verbatim: subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            if let trailing = self.trailing {
                Spacer(minLength: 1)
                VStack(alignment: .trailing, spacing: 8) {
                    Text(verbatim: trailing.0)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(verbatim: trailing.1)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    public init(
        image: Image,
        title: String,
        subtitle: String? = nil,
        trailing: (String, String)? = nil
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }
}

public extension LockRowView {
    
    enum Image {
        case loading
        case permission(PermissionType)
        case emoji(Character)
        case symbol(String)
        #if canImport(UIKit)
        case image(UIImage)
        #elseif canImport(AppKit)
        case image(NSImage)
        #endif
    }
}

extension LockRowView {
    
    struct ImageView: View {
        
        let image: Image
        
        var body: some View {
            switch image {
            case .loading:
                #if os(iOS)
                AnyView(ActivityIndicatorView(style: .large))
                #else
                AnyView(
                    ProgressView()
                        .progressViewStyle(.circular)
                )
                #endif
            case let .permission(permission):
                AnyView(
                    PermissionIconView(permission: permission)
                )
            case let .emoji(emoji):
                AnyView(
                    Text(verbatim: String(emoji))
                        .font(.system(size: 43))
                )
            case let .symbol(symbol):
                AnyView(
                    SwiftUI.Image(systemName: symbol)
                        .font(.system(size: 40))
                )
            case let .image(image):
                #if canImport(UIKit)
                AnyView(
                    SwiftUI.Image(uiImage: image)
                )
                #elseif canImport(AppKit)
                AnyView(
                    SwiftUI.Image(nsImage: image)
                )
                #endif
            }
        }
    }
}

// MARK: - Preview

struct LockRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            LockRowView(
                image: .loading,
                title: "Loading..."
            )
            LockRowView(
                image: .permission(.admin),
                title: "Setup",
                subtitle: "D39FE551-523F-4F64-96FC-4B828A1F8561"
            )
            LockRowView(
                image: .permission(.admin),
                title: "Lock Name",
                subtitle: "Anytime"
            )
            LockRowView(
                image: .permission(.owner),
                title: "My house",
                subtitle: "Owner"
            )
            LockRowView(
                image: .permission(.anytime),
                title: "Home",
                subtitle: "Anytime"
            )
            LockRowView(
                image: .permission(.scheduled),
                title: "Office",
                subtitle: "Scheduled"
            )
            LockRowView(
                image: .emoji("🔓"),
                title: "Unlock",
                subtitle: "By Alsey Coleman Miller",
                trailing: ("Today", "9:00AM")
            )
            LockRowView(
                image: .symbol("bonjour"),
                title: "Bonjour"
            )
            .symbolRenderingMode(.multicolor)
        }
    }
}
