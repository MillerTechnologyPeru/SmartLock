//
//  Event.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/8/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock

public extension LockEvent.EventType {
    
    var symbol: Character {
        switch self {
        case .setup:
            return "🔐"
        case .unlock:
            return "🔓"
        case .createNewKey:
            return "🔏"
        case .confirmNewKey:
            return "🔑"
        case .removeKey:
            return "🗑"
        }
    }
}
