//
//  LockStatus.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/23/22.
//

import Foundation
import AppIntents

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension LockEntity {
    
    enum LockStatus: UInt8, AppEnum {
        
        /// Initial Status
        case setup = 0x00
        
        /// Idle / Unlock Mode
        case unlock = 0x01
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation {
            "Lock Status"
        }
        
        static var caseDisplayRepresentations: [LockStatus : DisplayRepresentation] {
            [
                .setup: "Needs Setup",
                .unlock: "Ready to Unlock"
            ]
        }
    }
}
