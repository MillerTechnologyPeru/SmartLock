//
//  UUID.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 9/16/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public extension UUID {
    
    /// iBeacon Lock Notification
    static var lockBeaconNotification: UUID {
        return UUID(uuidString: "F6AC86F3-A97D-4FA7-8668-C8ECFD1E538D")!
    }
}
