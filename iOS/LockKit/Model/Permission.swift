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
        
        #if os(iOS)
        switch self {
        case .owner:
            return R.string.localizable.permissionOwner()
        case .admin:
            return R.string.localizable.permissionAdmin()
        case .anytime:
            return R.string.localizable.permissionAnytime()
        case .scheduled:
            return R.string.localizable.permissionScheduled()
        }
        #elseif os(watchOS)
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
        #endif
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
        #if os(iOS)
        return R.string.localizable.permissionScheduled()
        #elseif os(watchOS)
        return NSLocalizedString("Scheduled", tableName: nil, bundle: .lockKit, value: "Scheduled", comment: "Permission.Scheduled")
        #endif
    }
}
