//
//  SetupEventManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public final class SetupEventManagedObject: EventManagedObject {
    
    @nonobjc override public class var eventType: LockEvent.EventType { return .setup }
    
    internal convenience init(_ value: LockEvent.Setup, lock: LockManagedObject, context: NSManagedObjectContext) {
        
        self.init(context: context)
        self.identifier = value.id
        self.lock = lock
        self.date = value.date
        self.key = value.key
    }
}

public extension LockEvent.Setup {
    
    init?(managedObject: SetupEventManagedObject) {
        
        guard let id = managedObject.identifier,
            let date = managedObject.date,
            let key = managedObject.key
            else { return nil }
        
        self.init(id: id, date: date, key: key)
    }
}

// MARK: - IdentifiableManagedObject

extension SetupEventManagedObject: IdentifiableManagedObject { }

