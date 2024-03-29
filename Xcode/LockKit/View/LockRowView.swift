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
    
    #if !os(watchOS)
    public let trailing: (String, String)?
    #endif
    
    public var body: some View {
        HStack(alignment: .center, spacing: 3) {
            //
            HStack(alignment: .center, spacing: 16) {
                VStack {
                    ImageView(image: image)
                        .frame(width: imageSize, height: imageSize, alignment: .center)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: title)
                        .font(titleFont)
                    if let subtitle = subtitle {
                        Text(verbatim: subtitle)
                            .font(subtitleFont)
                            .foregroundColor(.gray)
                    }
                }
            }
            #if !os(watchOS)
            if let trailing = self.trailing {
                Spacer(minLength: 1)
                VStack(alignment: .trailing, spacing: 8) {
                    Text(verbatim: trailing.0)
                        .font(subtitleFont)
                        .foregroundColor(.gray)
                    Text(verbatim: trailing.1)
                        .font(subtitleFont)
                        .foregroundColor(.gray)
                }
            }
            #endif
        }
        .padding(8)
    }
    
    #if !os(watchOS)
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
    #else
    public init(
        image: Image,
        title: String,
        subtitle: String? = nil
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
    }
    #endif
}

private extension LockRowView {
    
    var titleFont: Font {
        #if os(iOS)
        .system(size: 19)
        #else
        .body
        #endif
    }
    
    var subtitleFont: Font {
        #if os(iOS)
        .system(size: 14)
        #else
        .callout
        #endif
    }
    
    var imageSize: CGFloat {
        #if os(iOS)
        50
        #elseif os(macOS)
        50
        #elseif os(watchOS)
        32
        #elseif os(tvOS)
        100
        #endif
    }
}

public extension LockRowView {
    
    enum Image {
        case loading
        case permission(PermissionType)
        case emoji(Character)
        case symbol(String)
        case image(SwiftUI.Image)
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
                        .font(.system(size: emojiSize))
                )
            case let .symbol(symbol):
                AnyView(
                    SwiftUI.Image(systemName: symbol)
                        .font(.system(size: symbolSize))
                )
            case let .image(image):
                AnyView(
                    image
                )
            }
        }
    }
}

private extension LockRowView.ImageView {
    
    var emojiSize: CGFloat {
        #if os(iOS)
        43
        #elseif os(macOS)
        43
        #elseif os(watchOS)
        43
        #elseif os(tvOS)
        75
        #endif
    }
    
    var symbolSize: CGFloat {
        #if os(iOS)
        40
        #elseif os(macOS)
        40
        #elseif os(watchOS)
        40
        #elseif os(tvOS)
        70
        #endif
    }
}

// MARK: - Extensions

public extension LockRowView {
    
    init(lock: LockCache) {
        self.init(lock: lock.name, permission: lock.key.permission)
    }
    
    init(lock name: String, permission: Permission) {
        self.init(
            image: .permission(permission.type),
            title: name,
            subtitle: permission.type.localizedText
        )
    }
}

// MARK: - Preview

#if DEBUG
struct LockRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            LockRowView(
                image: .loading,
                title: "Loading..."
            )
            LockRowView(
                image: .permission(.owner),
                title: "Setup",
                subtitle: "D39FE551-523F-4F64-96FC-4B828A1F8561"
            )
            LockRowView(
                image: .permission(.admin),
                title: "Lock Name",
                subtitle: "Admin"
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
                image: .symbol("bonjour"),
                title: "Bonjour"
            )
            .symbolRenderingMode(.multicolor)
            
            #if os(watchOS)
            LockRowView(
                image: .emoji("🔓"),
                title: "Unlock",
                subtitle: "By Alsey Coleman Miller"
            )
            #else
            LockRowView(
                image: .emoji("🔓"),
                title: "Unlock",
                subtitle: "By Alsey Coleman Miller",
                trailing: ("Today", "9:00AM")
            )
            #endif
            
        }
    }
}
#endif
