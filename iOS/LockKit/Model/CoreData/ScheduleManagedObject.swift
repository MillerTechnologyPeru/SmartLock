//
//  ScheduleManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public final class ScheduleManagedObject: NSManagedObject {
    
    internal convenience init(_ value: Permission.Schedule, context: NSManagedObjectContext) {
        
        self.init(context: context)
        self.expiry = value.expiry
        self.intervalMin = numericCast(value.interval.rawValue.lowerBound)
        self.intervalMax = numericCast(value.interval.rawValue.upperBound)
        self.sunday = value.weekdays.sunday
        self.monday = value.weekdays.monday
        self.tuesday = value.weekdays.tuesday
        self.wednesday = value.weekdays.wednesday
        self.thursday = value.weekdays.thursday
        self.friday = value.weekdays.friday
        self.saturday = value.weekdays.saturday
    }
}
