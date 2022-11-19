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
    
    @nonobjc override public class var eventType: LockEvent.EventType { return .unlock }
    
    internal convenience init(_ value: LockEvent.Unlock, lock: LockManagedObject, context: NSManagedObjectContext) {
        
        self.init(context: context)
        self.identifier = value.id
        self.lock = lock
        self.date = value.date
        self.key = value.key
        self.action = numericCast(value.action.rawValue)
    }
}

public extension LockEvent.Unlock {
    
    init?(managedObject: UnlockEventManagedObject) {
        
        guard let id = managedObject.identifier,
            let date = managedObject.date,
            let key = managedObject.key,
            let action = UnlockAction(rawValue: numericCast(managedObject.action))
            else { return nil }
        
        self.init(id: id, date: date, key: key, action: action)
    }
}

// MARK: - IdentifiableManagedObject

extension UnlockEventManagedObject: IdentifiableManagedObject { }
