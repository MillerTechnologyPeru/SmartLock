//
//  UnlockAction.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/23/22.
//

import Foundation
import AppIntents

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
enum UnlockActionAppEnum: UInt8, AppEnum {
    
    /// Unlock immediately.
    case `default` = 0b01
    
    /// Unlock when button is pressed.
    case button = 0b10
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Unlock Action"
    }
    
    static var caseDisplayRepresentations: [UnlockActionAppEnum : DisplayRepresentation] {
        [
            .default: "Default",
            .button: "Button"
        ]
    }
}
