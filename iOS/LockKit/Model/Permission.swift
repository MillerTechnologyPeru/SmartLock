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

public extension Permission.Schedule.Interval {
    
    /// 9 AM to 5 PM
    static var `default`: Permission.Schedule.Interval {
        return Permission.Schedule.Interval(rawValue: 9 * 60 ... (12 + 5) * 60)!
    }
}

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


public extension Permission.Schedule.Weekdays {
    
    var localizedText: String {
        
        let every = NSLocalizedString("Every", comment: "Permission.Scheduled.Weekdays.Every")
        
        if self == .none {
            
            return NSLocalizedString("Never", comment: "Permission.Scheduled.Weekdays.Never")
            
        } else if self == .all {
            
            return String(format: "%@ %@", every, NSLocalizedString("Day", comment: "Permission.Scheduled.Weekdays.Day"))
            
        } else {
            
            return String(format: "%@ %@", every, self.days.map({ $0.localizedText }).joined(separator: ", "))
        }
    }
}

public extension Permission.Schedule.Weekdays.Day {
    
    var localizedText: String {
        
        switch self {
        case .sunday:
            return NSLocalizedString("Sunday", comment: "Permission.Scheduled.Weekdays.Day.Sunday")
        case .monday:
            return NSLocalizedString("Monday", comment: "Permission.Scheduled.Weekdays.Day.Monday")
        case .tuesday:
            return NSLocalizedString("Tuesday", comment: "Permission.Scheduled.Weekdays.Day.Tuesday")
        case .wednesday:
            return NSLocalizedString("Wednesday", comment: "Permission.Scheduled.Weekdays.Day.Wednesday")
        case .thursday:
            return NSLocalizedString("Thursday", comment: "Permission.Scheduled.Weekdays.Day.Thursday")
        case .friday:
            return NSLocalizedString("Friday", comment: "Permission.Scheduled.Weekdays.Day.Friday")
        case .saturday:
            return NSLocalizedString("Saturday", comment: "Permission.Scheduled.Weekdays.Day.Saturday")
        }
    }
}
