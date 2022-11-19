//
//  PermissionAppEnum.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/23/22.
//

import Foundation
import AppIntents

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
enum PermissionAppEnum: UInt8, AppEnum {
    
    case owner          = 0x00
    case admin          = 0x01
    case anytime        = 0x02
    case scheduled      = 0x03
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Permission"
    }
    
    static var caseDisplayRepresentations: [PermissionAppEnum : DisplayRepresentation] {
        [
            .owner: "Owner",
            .admin: "Admin",
            .anytime: "Anytime",
            .scheduled: "Scheduled"
        ]
    }
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension PermissionAppEnum {
    
    var imageName: String {
        switch self {
        case .owner:
            return "permissionOwner"
        case .admin:
            return "permissionAdmin"
        case .anytime:
            return "permissionAnytime"
        case .scheduled:
            return "permissionScheduled"
        }
    }
}
