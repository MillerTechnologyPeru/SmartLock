//
//  Sidebar.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import SwiftUI
import LockKit

struct Sidebar: View {
    
    @EnvironmentObject
    var store: Store
    
    @State
    private var isExpanded: Bool = true
    
    var body: some View {
        List {
            DisclosureGroup(isExpanded: $isExpanded, content: {
                ForEach(peripherals, id: \.id) { (peripheral) in
                    NavigationLink(destination: {
                        Text(verbatim: peripheral.description)
                    }, label: {
                        Label(peripheral.description, systemImage: "antenna.radiowaves.left.and.right")
                    })
                }
            }, label: {
                HStack {
                    if store.isScanning {
                        ProgressView()
                            .frame(width: 16, height: 16, alignment: .leading)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                    Text("Nearby")
                }
            })
            
            DisclosureGroup(content: {
                NavigationLink(destination: {
                    Text(verbatim: "Key1")
                }, label: {
                    PermissionIconView(permission: .admin)
                        .frame(width: 16, height: 16, alignment: .center)
                    Text("Key1")
                })
            }, label: {
                Image(systemName: "key")
                Text("Keys")
            })
            
        }
    }
}

private extension Sidebar {
    
    var peripherals: [NativePeripheral] {
        store.peripherals.keys.sorted(by: { $0.id.description < $1.id.description })
    }
}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar()
    }
}
