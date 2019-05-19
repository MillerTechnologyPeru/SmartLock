//
//  Status.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 4/16/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

/// Lock status
public enum LockStatus: UInt8, Codable {
    
    /// Initial Status
    case setup = 0x00
    
    /// Idle / Unlock Mode
    case unlock = 0x01
}
