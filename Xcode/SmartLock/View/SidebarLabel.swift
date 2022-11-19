//
//  SidebarLabel.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

#if os(macOS)
import SwiftUI
import LockKit
import SFSafeSymbols

struct SidebarLabel: View {
    
    let title: String
    
    let image: Image
    
    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ImageView(image: image)
                .frame(width: 22, height: 22, alignment: .center)
            Text(verbatim: title)
        }
    }
}

extension SidebarLabel {
    
    enum Image {
        case loading
        case permission(PermissionType)
        case emoji(Character)
        case symbol(SFSymbol)
    }
}

extension SidebarLabel {
    
    struct ImageView: View {
        
        let image: SidebarLabel.Image
        
        var body: some View {
            switch image {
            case .loading:
                AnyView(
                    ProgressIndicatorView(style: .spinning, controlSize: .small)
                )
            case let .permission(permission):
                AnyView(
                    PermissionIconView(permission: permission)
                        .frame(width: 16, height: 16, alignment: .center)
                )
            case let .emoji(emoji):
                AnyView(
                    Text(verbatim: String(emoji))
                        .font(.system(size: 12))
                )
            case let .symbol(symbol):
                AnyView(
                    SwiftUI.Image(systemSymbol: symbol)
                        .font(.system(size: 15))
                )
            }
        }
    }
}

// MARK: - Preview

struct SidebarLabel_Previews: PreviewProvider {
    static var previews: some View {
        List {
            DisclosureGroup(isExpanded: State(initialValue: true).projectedValue, content: {
                SidebarLabel(title: "Setup", image: .permission(.owner))
                SidebarLabel(title: "Lock 1", image: .permission(.admin))
                SidebarLabel(title: "Lock 2", image: .permission(.anytime))
                SidebarLabel(title: "Lock 3", image: .permission(.scheduled))
                SidebarLabel(title: "Lock", image: .permission(.anytime))
                SidebarLabel(title: "⚠️ History ", image: .emoji("⚠️"))
            }, label: {
                SidebarLabel(title: "Loading...", image: .loading)
            })
            DisclosureGroup(isExpanded: State(initialValue: true).projectedValue, content: {
                SidebarLabel(title: "Setup", image: .permission(.owner))
                SidebarLabel(title: "Lock 1", image: .permission(.admin))
                SidebarLabel(title: "Lock 2", image: .permission(.anytime))
                SidebarLabel(title: "Lock 3", image: .permission(.scheduled))
                SidebarLabel(title: "Lock", image: .permission(.anytime))
            }, label: {
                SidebarLabel(title: "Nearby", image: .symbol(.antennaRadiowavesLeftAndRight)) // "antenna.radiowaves.left.and.right"
            })
            DisclosureGroup(content: {
                SidebarLabel(title: "Setup", image: .permission(.owner))
                SidebarLabel(title: "Lock 1", image: .permission(.admin))
                SidebarLabel(title: "Lock 2", image: .permission(.anytime))
                SidebarLabel(title: "Lock 2", image: .permission(.scheduled))
            }, label: {
                SidebarLabel(title: "Keys", image: .symbol(.key))
            })
        }
    }
}
#endif
