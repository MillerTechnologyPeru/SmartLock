//
//  KeyManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public final class KeyManagedObject: NSManagedObject {
    
    internal convenience init(_ value: Key, lock: LockManagedObject, context: NSManagedObjectContext) {
        self.init(context: context)
        self.identifier = value.identifier
        self.lock = lock
        self.name = value.name
        self.created = value.created
        self.permission = numericCast(value.permission.type.rawValue)
        if case let .scheduled(schedule) = value.permission {
            self.schedule = .init(schedule, context: context)
        }
    }
}

extension KeyManagedObject: IdentifiableManagedObject { }
