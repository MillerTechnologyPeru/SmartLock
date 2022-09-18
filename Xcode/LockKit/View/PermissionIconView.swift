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
    
    @State
    var permission: PermissionType = .admin
}

// MARK: - Preview

struct PermissionIconView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PermissionIconView()
                .padding(5.0)
                .preferredColorScheme(.light)
                .previewLayout(.sizeThatFits)
                .frame(width: 100, height: 100, alignment: .center)
        }
    }
}
