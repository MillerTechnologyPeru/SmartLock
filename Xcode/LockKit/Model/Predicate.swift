//
//  Predicate.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/21/22.
//

import Foundation
import CoreData
import Predicate

public extension LockEvent.Predicate {
    
    func toFoundation() -> NSPredicate {
        // CoreData predicate
        var subpredicates = [Predicate]()
        if let keys = self.keys, keys.isEmpty == false {
            
        }
        let predicate: Predicate = subpredicates.isEmpty ? .value(true) : .compound(.and(subpredicates))
        return predicate.toFoundation()
    }
}
