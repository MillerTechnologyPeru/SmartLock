//
//  SettingsRowView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/29/22.
//

#if os(iOS)
import SwiftUI

struct SettingsRowView <Destination: View> : View {
    
    let title: LocalizedStringKey
    
    let icon: SettingsIcon
    
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: { destination }, label: {
            LabelView(title: title, icon: icon)
        })
    }
}

extension SettingsRowView {
    
    struct LabelView: View {
        
        let title: LocalizedStringKey
        
        let icon: SettingsIcon
        
        var body: some View {
            HStack(alignment: .center, spacing: 16) {
                SettingsIconView(icon: icon)
                    .frame(width: 32, height: 32, alignment: .center)
                Text(title)
                Spacer(minLength: 0)
            }
        }
    }
}

#if DEBUG
struct SettingsRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section("Settings") {
                SettingsRowView(title: "Bluetooth", icon: .bluetooth, destination: AnyView(Text("")))
                SettingsRowView(title: "iCloud", icon: .cloud, destination: AnyView(Text("")))
            }
        }
    }
}
#endif
#endif
