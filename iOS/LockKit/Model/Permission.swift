//
//  Permission.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreLock

#if os(iOS)
import Rswift

public extension UIImage {
    
    convenience init(permission: Permission) {
        self.init(permissionType: permission.type)
    }
    
    convenience init(permissionType: PermissionType) {
        self.init(named: permissionType.image.name, in: .lockKit, compatibleWith: nil)!
    }
}

public extension PermissionType {
    
    var image: ImageResource {
        
        switch self {
        case .owner:
            return R.image.permissionBadgeOwner
        case .admin:
            return R.image.permissionBadgeAdmin
        case .anytime:
            return R.image.permissionBadgeAnytime
        case .scheduled:
            return R.image.permissionBadgeScheduled
        }
    }
}

#endif

public extension PermissionType {
    
    var localizedText: String {
        
        switch self {
        case .owner:
            return NSLocalizedString("Owner", comment: "Permission.Owner")
        case .admin:
            return NSLocalizedString("Admin", comment: "Permission.Admin")
        case .anytime:
            return NSLocalizedString("Anytime", comment: "Permission.Anytime")
        case .scheduled:
            return NSLocalizedString("Scheduled", comment: "Permission.Scheduled")
        }
    }
}

public extension Permission {
    
    var localizedText: String {
        
        switch self {
        case .owner, .admin, .anytime:
            return type.localizedText
        case let .scheduled(schedule):
            return schedule.localizedText
        }
    }
}

public extension Permission.Schedule {
    
    var localizedText: String {
        
        // FIXME: Localized schedule
        return NSLocalizedString("Scheduled", comment: "Permission.Scheduled")
    }
}
