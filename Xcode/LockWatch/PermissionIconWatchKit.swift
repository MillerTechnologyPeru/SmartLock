//
//  PermissionIconWatchKit.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/28/22.
//

#if os(watchOS)
import SwiftUI

public extension PermissionIconView {
    
    var body: some View {
        Image(permissionType: permission)
            .resizable(capInsets: .init(), resizingMode: .stretch)
    }
}
#endif
