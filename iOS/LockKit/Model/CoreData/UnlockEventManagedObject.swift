//
//  UnlockEventManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public final class UnlockEventManagedObject: EventManagedObject {
    
    @nonobjc override class var eventType: LockEvent.EventType { return .unlock }
    
    internal convenience init(_ value: LockEvent.Unlock, lock: LockManagedObject, context: NSManagedObjectContext) {
        
        self.init(context: context)
        self.identifier = value.identifier
        self.lock = lock
        self.date = value.date
        self.key = value.key
        self.action = numericCast(value.action.rawValue)
    }
}

public extension LockEvent.Unlock {
    
    init?(managedObject: UnlockEventManagedObject) {
        
        guard let identifier = managedObject.identifier,
            let date = managedObject.date,
            let key = managedObject.key,
            let action = UnlockAction(rawValue: numericCast(managedObject.action))
            else { return nil }
        
        self.init(identifier: identifier, date: date, key: key, action: action)
    }
}

// MARK: - IdentifiableManagedObject

extension UnlockEventManagedObject: IdentifiableManagedObject { }
