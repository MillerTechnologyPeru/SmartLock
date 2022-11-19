//
//  EventTypeAppEnum.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/24/22.
//

import AppIntents
import LockKit

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
enum EventTypeAppEnum: String, AppEnum {
        
    case setup          = "com.colemancda.Lock.Event.Setup"
    case unlock         = "com.colemancda.Lock.Event.Unlock"
    case createNewKey   = "com.colemancda.Lock.Event.CreateNewKey"
    case confirmNewKey  = "com.colemancda.Lock.Event.ConfirmNewKey"
    case removeKey      = "com.colemancda.Lock.Event.RemoveKey"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Event"
    }
    
    static var caseDisplayRepresentations: [EventTypeAppEnum : DisplayRepresentation] {
        [
            .setup: "Setup",
            .unlock: "Unlock",
            .createNewKey: "Create New Key",
            .confirmNewKey: "Confirm New Key",
            .removeKey: "Remove Key"
        ]
    }
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension EventTypeAppEnum {
    
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
