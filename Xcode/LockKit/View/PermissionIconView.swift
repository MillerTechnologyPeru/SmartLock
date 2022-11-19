//
//  PermissionIconView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/23/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import SwiftUI
import CoreLock

/// Renders lock permission icon.
public struct PermissionIconView: View {
    
    public let permission: PermissionType
    
    public init(permission: PermissionType) {
        self.permission = permission
    }
}

// MARK: - Preview

struct PermissionIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PermissionIconView(permission: .owner)
                .frame(width: 100, height: 100, alignment: .center)
            PermissionIconView(permission: .admin)
                .frame(width: 100, height: 100, alignment: .center)
            PermissionIconView(permission: .anytime)
                .frame(width: 100, height: 100, alignment: .center)
            PermissionIconView(permission: .scheduled)
                .frame(width: 100, height: 100, alignment: .center)
        }
    }
}
