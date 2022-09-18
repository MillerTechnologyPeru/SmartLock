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
        }
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
                title: "Loading...",
                subtitle: nil
            )
            LockRowView(
                image: .permission(.admin),
                title: "Lock Name",
                subtitle: "Anytime"
            )
            LockRowView(
                image: .permission(.admin),
                title: "Office door",
                subtitle: "Admin"
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
                image: .emoji("🔓"),
                title: "Unlock",
                subtitle: "By Alsey Coleman Miller"
            )
            LockRowView(
                image: .symbol("bonjour"),
                title: "Bonjour",
                subtitle: nil
            )
            .symbolRenderingMode(.multicolor)
        }
    }
}
